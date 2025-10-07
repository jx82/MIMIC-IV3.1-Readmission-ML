setup:
	pip install -r requirements.txt

label:
	@echo "Run SQL to create readmission labels (see sql/readmission_label.sql)"

train:
	@echo "Train baseline XGBoost (add your code under src/)"

lint:
	python -m pip install ruff && ruff check .
