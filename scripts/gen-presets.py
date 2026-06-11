import re
import os
import subprocess

def get_repo_root():
    try:
        return subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except Exception:
        # Fallback to current directory if not in git
        return os.getcwd()

REPO_ROOT = get_repo_root()
STOT_YML = os.path.join(REPO_ROOT, "templates/.agent-harness/role-models.yml")
PRESET_DIR = os.path.join(REPO_ROOT, "templates/.agent-harness/presets")
README = os.path.join(REPO_ROOT, "README.md")

def read_stot():
    with open(STOT_YML, 'r') as f:
        content = f.read()
    
    roles_start = content.find("roles:")
    header = content[:roles_start + 6]
    roles_text = content[roles_start + 6:]
    
    # parse roles
    role_blocks = re.findall(r'\n  (\w+):\n    cli: (.*?)\n    model: (.*?)\n    fallback: (.*?)\n    rationale: (.*?)(?=\n  \w+:|\Z)', "\n" + roles_text, re.DOTALL)
    
    return header, role_blocks

def promote_cli(cli, model, fallback, target_cli):
    if cli == target_cli:
        return cli, model, fallback
    
    fallbacks = [x.strip() for x in fallback.split(',')]
    target_idx = -1
    for i, f in enumerate(fallbacks):
        if f.startswith(target_cli + ':'):
            target_idx = i
            break
            
    if target_idx != -1:
        target_val = fallbacks.pop(target_idx)
        _, new_model = target_val.split(':', 1)
        fallbacks.insert(0, f"{cli}:{model}")
        return target_cli, new_model, ", ".join(fallbacks)
    
    return cli, model, fallback

def generate_preset_content(header, role_blocks, target_cli=None):
    out = [header]
    for role, cli, model, fallback, rationale in role_blocks:
        if target_cli:
            p_cli, p_model, p_fallback = promote_cli(cli, model, fallback, target_cli)
        else:
            p_cli, p_model, p_fallback = cli, model, fallback
            
        out.append(f"\n  {role}:\n    cli: {p_cli}\n    model: {p_model}\n    fallback: {p_fallback}\n    rationale: {rationale.strip()}")
    
    return "\n".join(out) + "\n"

def write_preset(name, content):
    os.makedirs(PRESET_DIR, exist_ok=True)
    with open(os.path.join(PRESET_DIR, f"preset-{name}.yml"), 'w') as f:
        f.write(content)
    print(f"Generated preset-{name}.yml")

def update_readme(role_blocks):
    with open(README, 'r') as f:
        content = f.read()

    # Generate role bullets
    bullets = []
    # Descriptions are hardcoded to match the original README, but we insert the STOT model
    descs = {
        'orchestrator': "Sits at the top of the workflow. Highly tool-agentic, low-latency, and coordinates the overall project state. It focuses on environment orchestration, git logistics, verification suites, and telemetry. Core features like cross-repository worktree monitoring, automated session summarization, and active agent handoff routing are **coming soon (upcoming role integration)**.",
        'planner': "The slow, high-reasoning \"architect\". It reads the requirement, analyzes the code context, and designs the bounded execution contract (`.worktree-task.md`) specifying Scope, Off-limits, and Verification steps.",
        'executor': "The precision coder. It is budget-friendly, highly focused, and operates strictly inside the isolated worktree sandbox, adhering strictly to the contract boundaries.",
        'verifier': "The quality gatekeeper. It automatically conducts code reviews, checks for style/security constraints, and runs PR-level checks. If verification fails, it can trigger a feedback loop back to the Planner or Executor.",
        'finisher': "Performs deterministic boundary validation (`wtcraft check`), test suite verification (`wtcraft verify`), and cleans up local worktree assets after a successful merge to keep the development disk clean. Additionally, in an upcoming release (integrating with PR #12), the Finisher will aggregate and report **token telemetry** to track cost, budget, and API usage per agent model (**Coming Soon**)."
    }

    for role, cli, model, fallback, _ in role_blocks:
        bullet = f"* **{role.capitalize()} (e.g., {model})**: {descs.get(role, '')}"
        bullets.append(bullet)

    injected = "\n<!-- wtcraft:models:start -->\n" + "\n\n".join(bullets) + "\n<!-- wtcraft:models:end -->\n"

    # Replace existing block if markers exist
    if "<!-- wtcraft:models:start -->" in content and "<!-- wtcraft:models:end -->" in content:
        content = re.sub(r'<!-- wtcraft:models:start -->.*<!-- wtcraft:models:end -->\n', injected, content, flags=re.DOTALL)
    else:
        # Fallback: append or tell user to place markers
        print("Markers not found in README.md. Please place <!-- wtcraft:models:start --> and <!-- wtcraft:models:end --> in README.md")
        return

    with open(README, 'w') as f:
        f.write(content)
    print("Updated README.md")

if __name__ == "__main__":
    header, role_blocks = read_stot()
    
    # 1. Generate preset-balanced (STOT)
    write_preset("balanced", generate_preset_content(header, role_blocks))
    
    # 2. Generate preset-anthropic (promote claude)
    write_preset("anthropic", generate_preset_content(header, role_blocks, "claude"))
    
    # 3. Generate preset-openai (promote codex)
    write_preset("openai", generate_preset_content(header, role_blocks, "codex"))
    
    # 4. Generate preset-google (promote gemini)
    write_preset("google", generate_preset_content(header, role_blocks, "gemini"))
    
    # 5. Update README
    update_readme(role_blocks)
