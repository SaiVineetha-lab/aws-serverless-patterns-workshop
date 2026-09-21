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
| [Module 4](module-4) | Asynchronous Invocation | Complete, deployed, 7/7 tests passing | Built with AWS SAM |

### Module 1 — Introduction to Serverless

Build and test a basic serverless application using AWS Lambda, Amazon DynamoDB, and Amazon
API Gateway. The application stores sample user information in DynamoDB and retrieves the
stored users through an API Gateway REST API.

### Module 4 — Asynchronous Invocation

Build a User Profile service using the CQRS and Event-Driven Architecture patterns. API
Gateway writes address commands directly to an Amazon EventBridge bus and favorite commands
directly to an Amazon SQS queue using mapping templates, so the caller is acknowledged
immediately while Lambda consumers process the work downstream. Reads go straight to
DynamoDB, separate from the write path.

See [module-4/README.md](module-4/README.md) for the full build, deploy and test instructions.

## AWS Region

```text
US East (Ohio)
Region: us-east-2
```
