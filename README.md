# AWS Serverless Patterns Workshop

## Team Information

- Team name: Trojans
- Member 1: Sai Vineetha Tirumalla
- Member 2: Shivani Naikoti
- Member 3: Mukesh Singh
- Member 4: Ranadhir

## GitHub Repository

https://github.com/SaiVineetha-lab/aws-serverless-patterns-workshop

## Workshop

AWS Serverless Patterns Workshop:

https://catalog.workshops.aws/serverless-patterns/en-US

## Modules

| Module | Pattern | Status | Notes |
| --- | --- | --- | --- |
| [Module 1](module-1) | Intro to Serverless | Complete | Built in the console |
| [Module 3](module-3) | Synchronous + Idempotence | Complete | Built with AWS SAM |
| [Module 4](module-4) | Asynchronous Invocation | Complete | Built with AWS SAM |
| [Module 5](module-5) | Polling | complete | Built with AWS SAM |

### Module 1 — Introduction to Serverless

Build and test a basic serverless application using AWS Lambda, Amazon DynamoDB, and Amazon
API Gateway. The application stores sample user information in DynamoDB and retrieves the
stored users through an API Gateway REST API.

### Module 3 — Introduction to Synchronous + Idempotence

In this module, we build an Orders service that lets customers manage their orders. Customers can create a new order, view a specific order, see a list of their orders, edit an order, or cancel it.
The service uses a shared Lambda layer to retrieve orders from DynamoDB. Order creation also includes idempotency, structured logging, and metrics so repeated requests do not create duplicate orders and the application is easier to monitor.
The project includes local tests that verify the order workflow and confirm that retrying the same request returns the existing order instead of creating another one.

### Module 4 — Asynchronous Invocation

Build a User Profile service using the CQRS and Event-Driven Architecture patterns. API
Gateway writes address commands directly to an Amazon EventBridge bus and favorite commands
directly to an Amazon SQS queue using mapping templates, so the caller is acknowledged
immediately while Lambda consumers process the work downstream. Reads go straight to
DynamoDB, separate from the write path.

See [module-4/README.md](module-4/README.md) for the full build, deploy and test instructions.

### Module 5 — Polling

Build an order status service that customers poll while their order is prepared and delivered.
Restaurants publish `order.updated` events to an EventBridge bus; a Lambda target writes the
new status to the Orders table; customers read the current status through the Orders API.
Status changes outlast a request/response cycle, and mobile clients are not reliably reachable
for webhooks, so polling is the simpler and more robust choice.

See [module-5/README.md](module-5/README.md) for the full build, deploy and test instructions.

## AWS Region

```text
US East (Ohio)
Region: us-east-2
```
