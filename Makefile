
deploy: zip_code
	terraform init
	terraform plan -out output/planned
	terraform apply output/planned

clean:
	terraform destroy -force
	rm -rf output/
	
zip_code:
	-mkdir output
	zip output/lambda.zip lambda_handler.py
