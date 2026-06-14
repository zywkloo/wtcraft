# wtcraft — git-native harness helper
# Derive the version from installed package metadata so there is no second
# hardcoded literal to drift out of sync with pyproject.toml.
try:
    from importlib.metadata import PackageNotFoundError, version

    try:
        __version__ = version("wtcraft")
    except PackageNotFoundError:
        __version__ = "0.0.0+source"
except ImportError:  # Python < 3.8
    __version__ = "0.0.0+source"
