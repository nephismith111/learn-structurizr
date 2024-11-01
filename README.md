# learn-structurizr

---

## Motivation

In my efforts to learn how to design high quality software architecture, I've found that documentation is critical.
If you ask a consultant, many will advise some kind of event storming session with the goal of determining clear boundaries for cohesive parts of the system. These can become aggregates, which are transaction boundaries for data consistency. Once determined, the data storage method can be strategically chosen (whether nosql or relational sql).
Unfortunately, the resulting storming session (often done with sticky notes) yields a model that doesn't last unless documented.

Simon Brown came up with the c4 model, which captures the idea that systems are fractal and people can't hold the whole thing in their head all at once.
In the c4 model, architects will do a landscape view of the major systems (workspaces). Then, create a workspace for each system. In each workspace, the system is described. 
What I like is that you essentially get a macro view with the ability to zoom in on medium sized details, and zoom in further if merited to small and perhaps micro details. Now it's not generally advised to store code in the c4 model, but it makes the system easy to communicate to others.
I also like that this system is code based which means it can be version controlled. It gives a way to articulate and justify why a system is architected the way it is, allowing perhaps many people to work on the same system and reason about it together toward the same common business goal.


### Project Setup

I prefer docker-compose deployment for onpremise structurizr. It's scalable. We'll probably use an nfs mount or something.

I got the structurizr cli from `https://github.com/structurizr/cli/releases/download/v2024.09.19/structurizr-cli.zip`

When possible, I prefer to use idempotent tools. If you put your workspace in the active directory, then you can call `apply_workspaces.sh` to apply it using the parameters set in the `./workspaces/.env` file


#### install yq

```bash
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y
```


~~### How to push dsl workspace (to json) to structurizr~~

```bash
./structurizr.sh push -id 123456 -key 1a130d2b... -secret a9daaf3e... -workspace workspace.dsl
```
