# Module 5 — Polling

Team Trojans: Sai Vineetha Tirumalla, Shivani Naikoti, Mukesh Singh, Ranadhir

Workshop: https://catalog.workshops.aws/serverless-patterns/en-US/module5

## What This Builds

An order status service customers can poll while their food is prepared and delivered.

Order status changes over minutes or hours, far longer than a request/response cycle. A
webhook would need the client reachable at the moment of the change, which phones and browsers
are not. Polling trades some efficiency for a client that works anywhere.

```text
restaurant  --(order.updated event)-->  Orders bus  -->  UpdateOrderStatusFunction  -->  Orders table
customer    --(GET /orders/{id})----->  Orders API  -->  reads current status
```

`RestaurantBus` decouples the producers from the table. Today the restaurant publishes status
changes; delivery riders and other services can be added later as extra targets without
touching the function that writes to DynamoDB.

| Resource | Purpose |
| --- | --- |
| `RestaurantBus` | EventBridge bus named `Orders-${Stage}` |
| `UpdateOrderStatusFunction` | Rule target: source `restaurant`, detail-type `order.updated` |

The function updates a nested attribute, which needs bound names because `status` and `data`
are DynamoDB reserved words:

```text
SET #data.#status = :status
```

## Files

- `orderstatus/template.yaml` — event bus, Lambda, EventBridge rule
- `orderstatus/src/api/update_order_status.py` — writes status to the Orders table
- `orderstatus/tests/integration/` — 2 integration tests
- `orderstatus/polling-api.sh` — polls the API every 2s until status is `IN-PROCESS`

## Prerequisite

Module 5 builds on the Module 3 state. This deploys it as the `ws-serverless-patterns` stack:

```bash
cd ~ && wget -q -O ws5.zip "https://ws-assets-prod-iad-r-iad-ed304a55c2ca1aee.s3.us-east-1.amazonaws.com/76bc5278-3f38-46e8-b306-f0bfda551f5a/module5/sam-python/ws-serverless-patterns-2026-08-20.zip" && unzip -q -o ws5.zip && cd ws-serverless-patterns && sam build && sam deploy --guided --stack-name ws-serverless-patterns --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

If you already deployed the Module 4 prerequisite under the same stack name, this updates that
stack in place to the Module 3 state. That is expected.

## Deploy

Look up the two parameter values, both nested stacks have random suffixes:

```bash
ORDERS_STACK=$(aws cloudformation describe-stacks --query "Stacks[?starts_with(StackName,'ws-serverless-patterns-orders')].StackName | [0]" --output text) && USERS_STACK=$(aws cloudformation describe-stacks --query "Stacks[?starts_with(StackName,'ws-serverless-patterns-users')].StackName | [0]" --output text) && echo "ORDERS_STACK=$ORDERS_STACK" && echo "USERS_STACK=$USERS_STACK" && aws cloudformation describe-stacks --stack-name $ORDERS_STACK --query "Stacks[0].Outputs[?OutputKey=='OrdersTable'].OutputValue" --output text && aws cloudformation describe-stacks --stack-name $USERS_STACK --query "Stacks[0].Outputs[?OutputKey=='UserPool'].OutputValue" --output text
```

```bash
cd ~/aws-serverless-patterns-workshop/module-5/orderstatus && sam build && sam deploy --guided --stack-name ws-serverless-patterns-polling --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
```

Enter the OrdersTable name for `OrdersTablename` and the pool id for `UserPool`. Accept the
defaults for the rest.

## Test

The harness needs three variables. `CLIENT_ID` is the Cognito app client, not the user pool:

```bash
export ORDER_STATUS_STACK_NAME=ws-serverless-patterns-polling && export ORDERS_STACK_NAME=$ORDERS_STACK && export CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id $(aws cloudformation describe-stacks --stack-name $USERS_STACK --query "Stacks[0].Outputs[?OutputKey=='UserPool'].OutputValue" --output text) --query "UserPoolClients[0].ClientId" --output text) && echo "CLIENT_ID=$CLIENT_ID"
```

```bash
python3 -m pip install -q -r tests/requirements.txt && python3 -m pytest tests/integration -v
```

Expect `2 passed`:

- `test_order_status` — a customer can read their order, seeded as `ACKNOWLEDGED`
- `test_order_update_process` — publishing `order.updated` to the bus changes the status a
  later read returns

## Watch Polling Work

```bash
./polling-api.sh "<OrdersServiceEndpoint>/orders/2" "<IdToken>"
```

It requests every 2 seconds and stops when status reaches `IN-PROCESS`. Publish an event from
another shell to watch it flip.

## Deviation From the Workshop

The workshop adds `AWSLambdaPowertoolsPython:20` to `Globals`. That layer breaks on
`python3.12` because its dependencies import `distutils`, removed by PEP 632 — the same
failure documented in [module 4](../module-4/README.md).

Here it is simply dropped, because `update_order_status.py` imports only `json`, `os`, `boto3`
and `decimal`. Nothing in this module uses Powertools, so the layer was dead weight.

## Clean Up

```bash
sam delete --stack-name ws-serverless-patterns-polling
```
