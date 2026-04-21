# Specific secrets and variables for the Python/Poetry build flavour

As explained, these adds up to the [general secrets](../secrets-n-variables.md).

```yaml
# Used during releasing, points to your PyPI API token
POETRY_PYPI_TOKEN_PYPI: ${{secrets.POETRY_PYPI_TOKEN_PYPI}}

```