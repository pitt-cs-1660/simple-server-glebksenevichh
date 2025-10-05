# use python as base image
FROM python:3.12-slim AS build
    # install uv package manager
    COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
    # set workdir
    WORKDIR /app
    # copy pyproject.toml
    COPY pyproject.toml ./ 
    # install python dependencies using uv into a virtual environment
    RUN uv sync --no-install-project --no-editable
    # copy source code 
    COPY cc_simple_server/ ./cc_simple_server/
    COPY tests/ ./tests/
    COPY README.md ./
    # install complete project
    RUN uv sync --no-editable


FROM python:3.12-slim AS final
    # activate venv
    ENV VIRTUAL_ENV=/app/.venv
    ENV PATH="/app/.venv/bin:${PATH}"
    ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

    WORKDIR /app

    # copy the venv from build stage
    COPY --from=build --chown=app:app /app/.venv /app/.venv
    # copy app source code
    COPY --from=build --chown=app:app /app/cc_simple_server/ ./cc_simple_server
    # copy tests
    COPY --from=build --chown=user:user /app/tests/ ./tests/

    # create non-root user
    RUN useradd -m user
    RUN chown -R user:user /app
    USER user

    # expose port 8000
    EXPOSE 8000


    # Set CMD to run FastAPI server on 0.0.0.0:8000
    CMD ["uvicorn", "cc_simple_server.server:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]

