## Dockerzon

(Note, this app serves as a demo app to be deployed onto ECS)

A tailored version of `dockerzon` used in `Scaling Docker on AWS` course on udemy.

It's created to demonstrate how you can have the trio - react app + nginx + express work together in docker. It's comprised of:

- frontend
  - nginx
- express

Responsibilities:

- frontend - a sample react app
- nginx - reverse proxy + static assets serving
- express - api server

## How to kickstart
First, install dependencies for `frontend` and `express` respectively.
Then, run `yarn build` from inside `frontend` folder which results in `build` directory including production-ready artifacts.

Lastly, run `docker-compose up` from project root and navigate to `http://localhost:4000` in your browser once containers are up and running.

## Provision resources
We use terraform for this. See example below:

```shell
# from infra folder
$ terraform apply -var-file="dev.tfvars"
```

## TODOs
- Add https support
- Incorporate ElasticCache and RDS and deploy the whole stack onto ECS

## Reference links
[url rewrite in reverse proxy](https://serverfault.com/questions/379675/nginx-reverse-proxy-url-rewrite)


## To investigate
(service web) was unable to place a task because no container instance met all of its requirements. The closest matching (container-instance a10cdad0-cb39-48b1-a533-b545396b6493) has insufficient CPU units available. For more information, see the Troubleshooting section of the Amazon ECS Developer Guide.
