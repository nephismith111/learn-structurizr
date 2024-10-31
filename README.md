# learn-structurizr

---

## Motivation

I my research for high quality software architecture, it's important to document what is done.
Ideally, a software system is described initially using event storming perhaps along with process storming, but this medium does not scale nor communicate details well - it's a good and important first draft.

Simon Brown came up with the c4 model, which allows people to describe the 50,000 foot view of the software system, then zoom in and see the 1,000 foot view, then the 10 foot view. All of this can be done using a diagramming system described in code (which means it can be version controlled), and where it can be rendered in different ways.

Without good documentation, there is little to prevent the system from becoming a big ball of mud. This dovetails in nicely with DDD by providing the practical, lasting documentation.


### Project Setup

I prefer docker-compose deployment for onpremise structurizr. It's scalable. We'll probably use an nfs mount or something.

I got the structurizr cli from `https://github.com/structurizr/cli/releases/download/v2024.09.19/structurizr-cli.zip`

### How to push dsl workspace (to json) to structurizr

```bash
./structurizr.sh push -id 123456 -key 1a130d2b... -secret a9daaf3e... -workspace workspace.dsl
```
