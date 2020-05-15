# Creating a POST API using API Gateway, Lambda and DynamoDB

Pre-reqs:
- Valid AWS credentials
- Terraform 0.12+
- curl
- zip

1. Deploy it:

`make deploy`

2. Test it:

`curl -v -X POST https://k1fftxlfvf.execute-api.ap-southeast-2.amazonaws.com/default/customers -d "{ \"firstname\": \"Your Name here\", \"lastname\": \"Your Name here\", \"email\": \"Your Name here\"}"`

3. Clean it:

`make clean`