# Module 4 — Asynchronous Invocation

Team Trojans: Sai Vineetha Tirumalla, Shivani Naikoti, Mukesh Singh, Ranadhir

Workshop: https://catalog.workshops.aws/serverless-patterns/en-US/module4

Deployed in `us-east-2`, 7/7 integration tests passing.

## What This Builds

A User Profile service using CQRS, where writes are decoupled from reads.

| | Write path | Read path |
| --- | --- | --- |
| Address | API Gateway → EventBridge bus → Lambda → DynamoDB | Lambda → DynamoDB |
| Favorite | API Gateway → SQS queue → Lambda → DynamoDB | Lambda → DynamoDB |

The key idea is that API Gateway writes to the bus and the queue **directly**, through VTL
mapping templates, with no Lambda in the request path. The caller is acknowledged immediately
while consumers process the work downstream.

| Endpoint | Integration |
| --- | --- |
| `POST /address` | EventBridge `PutEvents`, detail-type `address.added` |
| `PUT /address/{addressId}` | EventBridge `PutEvents`, detail-type `address.updated` |
| `DELETE /address/{addressId}` | EventBridge `PutEvents`, detail-type `address.deleted` |
| `POST /favorite` | SQS `SendMessage`, command `AddFavorite` |
| `DELETE /favorite/{restaurantId}` | SQS `SendMessage`, command `DeleteFavorite` |
| `GET /address`, `GET /favorite` | Lambda proxy |

Cognito guards every endpoint. The user id comes from `$context.authorizer.claims.sub`, so the
client cannot spoof it.

## Files

- `userprofile/template.yaml` — 16 resources: EventBridge bus, SQS queue, 2 DynamoDB tables,
  6 Lambdas, 2 IAM roles, API Gateway
- `userprofile/api.yaml` — OpenAPI 3.0 definition with the mapping templates
- `userprofile/src/api/` — Lambda handlers (provided by the workshop)
- `userprofile/tests/integration/` — 7 integration tests

## Deploy

Requires the Module 2 stack. Run in AWS CloudShell, region `us-east-2`.

```bash
sudo dnf install -y python3.12 python3.12-pip
```

```bash
cd ~ && wget -q -O ws.zip "https://ws-assets-prod-iad-r-iad-ed304a55c2ca1aee.s3.us-east-1.amazonaws.com/76bc5278-3f38-46e8-b306-f0bfda551f5a/module4/sam-python/ws-serverless-patterns-2026-08-20.zip" && unzip -q ws.zip && cd ws-serverless-patterns && sam build && sam deploy --guided --stack-name ws-serverless-patterns --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

Get the User Pool id (the nested stack has a random suffix):

```bash
USERS_STACK=$(aws cloudformation describe-stacks --query "Stacks[?starts_with(StackName,'ws-serverless-patterns-users')].StackName | [0]" --output text) && aws cloudformation describe-stacks --stack-name $USERS_STACK --query "Stacks[0].Outputs[?OutputKey=='UserPool'].OutputValue" --output text
```

```bash
cd ~/aws-serverless-patterns-workshop/module-4/userprofile && sam build && sam deploy --guided --stack-name ws-serverless-patterns-userprofile --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

## Test

```bash
export USERS_STACK_NAME=$USERS_STACK && export USERPROFILE_STACK_NAME=ws-serverless-patterns-userprofile && python3 -m pip install -q -r tests/requirements.txt && python3 -m pytest tests/integration -v
```

Expect `7 passed` — address add/update/delete, favorite add/delete, request validation, and a
401 without a token. Rerun once if a test fails; the write paths are async and the tests only
sleep 1-2 seconds.

## Deviation From the Workshop

The workshop pins `AWSLambdaPowertoolsPython:20` in `Globals` while setting `Runtime:
python3.12`. That layer's dependencies import `distutils`, removed in Python 3.12, so every
function fails at init:

```text
Runtime.ImportModuleError: No module named 'distutils'
```

The GETs return `502`. The POSTs still return `200`, because API Gateway answers before any
Lambda runs — so the writes fail silently and the tables stay empty.

Fix: drop `Layers` and declare `aws-lambda-powertools[tracer]` in a `requirements.txt` under
each `CodeUri`, so `sam build` bundles a current version. SAM only reads `requirements.txt`
from inside the function directory, not the project root.

## Clean Up

```bash
sam delete --stack-name ws-serverless-patterns-userprofile
```
