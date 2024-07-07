

.PHONY: jupyter-server
jupyter-server:
	poetry run jupyter-notebook

.PHONY: jupyter-server-headless
jupyter-server-headless:
	poetry run jupyter-notebook --no-browser