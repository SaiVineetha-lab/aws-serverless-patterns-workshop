# Module 4 — Asynchronous Invocation

## Team Information

- Team name: Trojans
- Member 1: Sai Vineetha Tirumalla
- Member 2: Shivani Naikoti
- Member 3: Mukesh Singh
- Member 4: Ranadhir

## Workshop

https://catalog.workshops.aws/serverless-patterns/en-US/module4

## Objective

Build a User Profile service using the CQRS and Event-Driven Architecture patterns, so that
write commands are decoupled from the read models and from the downstream services that react
to them.

- **Address Service** — API Gateway puts address change commands directly onto an Amazon
  EventBridge event bus via a mapping template. Lambda functions subscribed to the bus apply
  the change to DynamoDB. The caller gets an immediate acknowledgement instead of waiting.
- **Favorite Service** — API Gateway puts favorite commands directly onto an Amazon SQS queue,
  also via a mapping template. A Lambda consumer drains the queue and writes to DynamoDB.
- Reads (`list_user_addresses`, `list_user_favorites`) go straight to DynamoDB, separate from
  the write path.

## Services Used

| Service | Role |
| --- | --- |
| Amazon EventBridge | Event bus for address change commands |
| Amazon SQS | Queue for favorite add/delete commands |
| Amazon API Gateway | REST front door; mapping templates integrate directly with EventBridge and SQS |
| AWS Lambda | Command handlers and query handlers |
| Amazon DynamoDB | Address and favorite data stores |
| Amazon Cognito | Authentication for the API |
| AWS SAM | Infrastructure as code (`template.yaml`) |
| OpenAPI | API definition consumed by API Gateway |

## Prerequisite

Module 2 resources must be deployed as the `ws-serverless-patterns` stack. To start from a
known-good state instead:

```bash
wget -O ws-serverless-patterns.zip "https://ws-assets-prod-iad-r-iad-ed304a55c2ca1aee.s3.us-east-1.amazonaws.com/76bc5278-3f38-46e8-b306-f0bfda551f5a/module4/sam-python/ws-serverless-patterns-2026-08-20.zip"
unzip ws-serverless-patterns.zip
cd ws-serverless-patterns
sam build
sam deploy --guided --stack-name ws-serverless-patterns --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

## Project Layout

`userprofile/` is the module 4 start state, taken from the workshop's `module4_setup.sh`.
It is a self-contained SAM project separate from the module 2 stack.

```text
userprofile/
├── events/event.json
├── requirements.txt
├── src/api/
│   ├── address/
│   │   ├── add_user_address.py
│   │   ├── delete_user_address.py
│   │   ├── edit_user_address.py
│   │   └── list_user_addresses.py
│   └── favorites/
│       ├── list_user_favorites.py
│       └── process_favorites_queue.py
├── template.yaml
└── tests/
    ├── integration/
    │   ├── conftest.py
    │   ├── test_api_gateway_favorites.py
    │   └── test_api_gateway_user_addresses.py
    └── requirements.txt
```

`template.yaml` ships as an empty skeleton. The workshop steps fill in `Globals`, `Resources`
and `Outputs`.

## Workshop Steps

| Step | Page |
| --- | --- |
| Module Setup | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/setup |
| 1 — Create Address service | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/address-service |
| 1.2 — Add Business Logic | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/bizlogic |
| 1.3 — Define the API | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/openapi |
| 1.4 — Create the API | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/create-api |
| 1.5 — List Addresses | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/get-address |
| 1.6 — Integration tests | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/integration-test |
| 2 — Create Favorite service | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/favorites-service |
| 2.1 — Connect the API | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/connect-fav-api |
| 2.2 — Integration tests — Favorites | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/favorites-integration-tests |
| 3 — Clean up | https://catalog.workshops.aws/serverless-patterns/en-US/module4/sam-python/clean-up-en |

## Running in AWS CloudShell

CloudShell already has the AWS CLI, SAM CLI, git and your console credentials, so there is
nothing to install and no `aws login` step. Open CloudShell from the console toolbar with the
region set to **us-east-2**.

Only `$HOME` survives between sessions. Do all work under `~/`.

### 1. Check the Python runtime

`sam build` needs a `python3.12` binary to match the Lambda runtime.

```bash
python3 --version
```

If it is not 3.12, install it (repeat each session, `dnf` writes outside `$HOME`):

```bash
sudo dnf install -y python3.12
```

### 2. Deploy the Module 2 prerequisite stack

Skip if `ws-serverless-patterns-users` already exists in CloudFormation.

```bash
cd ~ && wget -O ws-serverless-patterns.zip "https://ws-assets-prod-iad-r-iad-ed304a55c2ca1aee.s3.us-east-1.amazonaws.com/76bc5278-3f38-46e8-b306-f0bfda551f5a/module4/sam-python/ws-serverless-patterns-2026-08-20.zip" && unzip -q ws-serverless-patterns.zip && cd ws-serverless-patterns && sam build && sam deploy --guided --stack-name ws-serverless-patterns --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

### 3. Get this branch

```bash
cd ~ && git clone -b module-4-async-invocation https://github.com/SaiVineetha-lab/aws-serverless-patterns-workshop.git && cd aws-serverless-patterns-workshop/module-4/userprofile
```

### 4. Look up the User Pool id

```bash
aws cloudformation describe-stacks --stack-name ws-serverless-patterns-users --query "Stacks[0].Outputs[?OutputKey=='UserPool'].OutputValue" --output text
```

### 5. Build and deploy

```bash
sam build && sam deploy --guided --stack-name ws-serverless-patterns-userprofile --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

Enter the User Pool id when prompted for `UserPool`. Accept the defaults for everything else.

### 6. Read the outputs

```bash
aws cloudformation describe-stacks --stack-name ws-serverless-patterns-userprofile --query "Stacks[0].Outputs" --output table
```

## Integration Tests

7 tests: 4 for the Address service, 3 for the Favorite service.

The harness reads both CloudFormation stacks' outputs, creates two confirmed Cognito test
users with passwords from Secrets Manager, and clears the address table before the run.
Export both stack names first or the fixture cannot resolve the outputs.

```bash
export USERS_STACK_NAME=ws-serverless-patterns-users
export USERPROFILE_STACK_NAME=ws-serverless-patterns-userprofile
pip3 install --user -r tests/requirements.txt
python3 -m pytest tests/integration -v
```

Expect `7 passed`. If some fail on the first run, wait 1-2 minutes and rerun: the write paths
are asynchronous and the tests only sleep 1-2 seconds before asserting.

| Test | Verifies |
| --- | --- |
| `test_add_user_address_with_invalid_fields` | request validator rejects a body missing `line1`/`line2` with 400 |
| `test_add_user_address` | POST returns 200, address lands in DynamoDB via EventBridge |
| `test_update_user_address` | PUT propagates all five fields |
| `test_delete_user_address` | DELETE removes the address |
| `test_access_to_the_favorites_without_authentication` | Cognito authorizer returns 401 |
| `test_add_user_favorite` | POST returns 200, favorite lands in DynamoDB via SQS |
| `test_delete_user_favorite` | DELETE removes the favorite |

## Clean Up

```bash
sam delete --stack-name ws-serverless-patterns-userprofile
```
