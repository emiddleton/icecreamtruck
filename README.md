# IcecreamTruck

IcecreamTruck is a ruby on rails based json web app for managing purchases and inventory on an icecream truck.

## Prerequisites

This application has been developed in Linux under a ruby environment managed by `rvm`.  It is highly recommended that you use `rvm` or `rbenv` to manage the ruby environment for this application.  If you have `rvm` installed it will guide you through setting up your environment when you change into the source directory on the command line.

It should run under OSX and windows with WSL but I do not have the environments to test this.  If you have a problem please create a ticket in github.

It is assumed you have a recent version of `docker` and `docker-compose` setup and running on your system.

The application also requires a postgresql database which we will run in docker.

## Installation

Clone the code from github, change into the directory and run bundle install using the commands given bellow.

```console
git clone https://github.com/emiddleton/icecreamtruck.git
cd icecreamtruck
bundle install
```

## Database setup

For local development and running tests you will need to setup a dockerized postgresql server using the following commands.

```console
docker run -e POSTGRES_USER=developer \
           -e POSTGRES_PASSWORD=development-password \
           -p 0.0.0.0:5432:5432 \
           -d postgres \
           postgres -N 1000
```

When this completes you will need to create the initial database with

```console
rails db:create db:migrate db:seed
```

### What to do if you have an existing postgresql server running
  
If you have an existing postgresql server running on your machine the port it is using will conflict with the one the docker instance is exposed on.  You will need to either stop the existing server before running the above command or change the port number the dockerized postgresql is exposed on.  The process for running docker on a different port is explained bellow.  Start by running the dockerized postgresql with the below command which will expose it on the first available port

```console
docker run -e POSTGRES_USER=developer \
           -e POSTGRES_PASSWORD=development-password \
           -p 0.0.0.0:0:5432 \
           -d postgres \
           postgres -N 1000
```

To find which port was, used run the `docker ps` command.  In the example below postgresql is being exposed on port 49153

```console
$ docker ps
CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS                     NAMES
702e80ab39a6   postgres   "docker-entrypoint.s…"   4 seconds ago    Up 2 seconds    0.0.0.0:49153->5432/tcp   suspicious_wilbur
```

You will now need to update the database port number in the `config/database.yml` file to point to the port your database is exposed on, as shown in this example bellow (in the examples the port is 49143).

```yaml
..
development_default: &development_default
  <<: *default
  host: 127.0.0.1
  port: 49153
...
```

When this completes you will need to create the initial database with

```console
rails db:create db:migrate db:seed
```

## Running Tests

Tests are implemented in `rspec`.  To run all test type `rspec` in the source root directory.  Code coverage report will be generated in coverage/index.html when the test complete.

## Testing the Production Like Environment

You can run the application locally using docker-compose with the following command which will start the application in a production like environment, using its own database and exposing an API on localhost port 80

```console
docker-compose run web-api rails db:create db:migrate db:seed && \
  docker-compose up
```

you can use control-c to stop the running containers

## Upgrading the Production Like Environment

To upgrade just the rails containers

1. use control-c to stop the running containers

2. run the following.

```console
docker-compose rm --force web-api && \
  docker-compose up --no-start --no-recreate --build web-api && \
  docker-compose up
```

## Removing the Production Like Environment

**WARN: this will loose all data in the containers database**

1. Use control-c to stop running containers

2. remove all running and stopped containers (WARN: this will destroy all data in database)

```console
docker-compose kill && \
  docker-compose rm
```

## API

The API has six endpoints listed below.  The API calls are document in more detail below.
```
        Prefix Verb URI Pattern                    Controller#Action
  cancel_order PUT  /orders/:id/cancel(.:format)   orders#cancel    Cancel an order
complete_order PUT  /orders/:id/complete(.:format) orders#complete  Mark an order as Delivered to customer
        orders GET  /orders(.:format)              orders#index     List all orders with filters/sorting/paging
               POST /orders(.:format)              orders#create    Create a new order
         items GET  /items(.:format)               items#index      List all items with filters/sorting/paging
         sales GET  /sales(.:format)               items#sales      List all items sales with filters/sorting/paging
```

All requests should use the following headers

```
Accept:       application/json
Content-type: application/json
```

Items and Orders use a database generated UUID for their `id`.  Monetary amounts are given as integers in the
smallest indivisible unit for a given currency (eg. 1 yen for JPY and 1 cent for USD).

### Get list of items

Gets a list of all items on sale with optional filtering, sorting and paging.
This list will include all items even those that are not in stock

#### Filters - optional

Query filters are given as url query parameters.  They have the form

```
'q[' + attribute '_' + predicate + ']=' value
```

where attribute is one of `name`,`price` or `quantity` and the predicates are any of those listed
on the ransack site at https://github.com/activerecord-hackery/ransack#search-matchers

#### Sort order - optional

```
'q[s]' + attribute + '%20' + order
```

order can be `desc` or `asc`

#### Paging - optional

```
'page=' + number
```

```
Request
  Method:   GET
  URL:      /items

  Optional Filter
    QUERY:  q[attribute_predicate]=value
    SORT:   q[s]=attribute%20desc

Response:

  Headers:
            Current-Page: The page that was returned
            Page-Items:   Number of items per page
            Total-Pages:  Total number of pages
            Total-Count:  Total number of scores

  Body:     "[
              {
                "id": "ITEM_UUID",
                "name": "ITEMS_NAME",
                "price": PRICE_PER_ITEM,
                "quantity": NUMBER_OF_ITEMS_IN_STOCK
              }
              ...
            ]"
```
#### Usage

* Getting list the first page of items whose name start with 'choc' in ascending alphabetic order.

```console
curl -v -H "Accept: application/json" \
        -H "Content-type: application/json" \
        -X GET -G http://localhost/items \
        -d "page=1&q[name_start]=choc&q[s]=name%20asc" | jq
```

### Make an order

```
Request
  Method:   POST
  URL:      /orders

  BODY:     "{
              "order": {
                "name": "CUSTOMER_NAME",
                "request_id": "UUID",
                "order_items": [
                  {
                    "item_id": "ITEM_UUID",
                    "name": "ITEM_NAME",
                    "quantity": NUMBER_TO_PURCHASE
                  },
                  ...
                ],
                "payment" {
                  "card_number": "CREDIT_CARD_NUMBER",
                  "expiry_date": "CREDIT_CARD_EXPIRY_DATE"
                }
              }
            }"

Response:
  Status:   200 OK   
  Body:     "{
              "order": {
                "id": "ORDER_UUID",
                "name": "CUSTOMER_NAME",
                "request_id": "REQUEST_UUID",
                "transaction_id": "TRANSACTION_UUID",
                "created_at": "TIME_ORDER_WAS_MADE",
                "updated_at": "LAST_UPDATE_TIME",
                "order_items": [
                  {
                    "item_id": "ITEM_UUID",
                    "name": "ITEM_NAME",
                    "quantity": NUMBER_TO_PURCHASE
                  },
                  ...
                }
              }
            }"

Failure:
  Status:   422 Unprocessable Entity
  Body:     "{"message":"Validation failed: VALIDATION_FAILURE_MESSAGE"}

  Status:   409 Unprocessable Entity
  Body:     "{"message":"This order has already been received."}
```
#### Usage

* request_id is a uuid and must be unique for each order (used to avoid orders being repeat posted)
* item_id is the uuid for an item returned from the items list api above

```console
curl -v -H "Accept: application/json" \
        -H "Content-type: application/json" \
        -X POST -d '{"order":{
          "name": "Mark",
          "request_id": "8b51b805-c1b2-4121-be48-84f99e5bc9ee",
          "order_items": [{
            "item_id": "[ITEM_UUID]",
            "quantity": 5
          }],
          "payment": {
            "card_number":"6771-8981-0384-7613",
            "expiry_date":"27-03"
          }}}' \
        http://localhost/orders | jq
```

### Get list of all orders

This list of all orders in all states with optional filtering, sorting and paging.

#### Filters - optional

Query filters are given as url query parameters.  They have the form

```
'q[' + attribute '_' + predicate + ']=' value
```

where attribute is one of `request_id`, `name` or `status` and the predicates are any of those listed
on the ransack site at https://github.com/activerecord-hackery/ransack#search-matchers

#### Sort order - optional

```
'q[s]' + attribute + '%20' + order
```

order can be `desc` or `asc`

#### Paging - optional

```
'page=' + number
```

```
Request
  Method:   GET
  URL:      /orders

  Optional Filter
    QUERY:  q[attribute_predicate]=value
    SORT:   q[s]=attribute%20desc

Response:

  Headers:
            Current-Page: The page that was returned
            Page-Items:   Number of items per page
            Total-Pages:  Total number of pages
            Total-Count:  Total number of scores

  Body:     "[
              {
                "id": "ORDER_UUID",
                "name": "CUSTOMER_NAME",
                "status": "ORDER_STATUS",
                "request_id": "REQUEST_UUID",
                "transaction_id": "TRANSACTION_UUID",
                "created_at": "TIME_ORDER_WAS_MADE",
                "updated_at": "LAST_UPDATE_TIME",
                "order_items": [
                  {
                    "item_id": "ITEM_UUID",
                    "quantity": NUMBER_PURCHASED
                  },
                  ...
                ]
              }
              ...
            ]"
```
#### Usage

* get the first page of orders waiting to be delivered with oldest first

```console
curl -v -H "Accept: application/json" \
        -H "Content-type: application/json" \
        -X GET -G http://localhost/orders \
        -d "page=1&q[status_eq]=payed&q[s]=updated_at%20asc" | jq
```

### Complete order by id

* complete an order that has been payed for.

```
Request
  Method:   PUT
  URL:      /orders/:ORDER_UUID/complete

Response:
  Status:   204 No Content

Failure:
  Status:   422 Unprocessable Entity
            "{
              "message": "Validation failed: Already completed."
            }"

  Status:   422 Unprocessable Entity
  Body:     "{
              "message": "Payment must be completed"
            }"
```

#### Usage

* you need to replace [ORDER_UUID] in the command below with one returned from the list of all orders

```console
curl -v -H "Accept: application/json" \
        -H "Content-type: application/json" \
        -X PUT -G http://localhost/orders/[ORDER_UUID]/complete | jq
```

### Cancel order by id

* Cancelling an order will refund any payment made and return all pre-reserved stock.
* The API assumes that stock will be returned when order cancellation occurs.  In cases where this is
  not possible the lost stock would be considered as spoilage and be removed from the listed stock through
  and API for handling spoilage which is outside the scope of this problem.
* If an order has a `paying` status when canceling its status will be changed to `check_refund`
  pre-reserved stock will be returned but no payment refund will occur because it is not possible
  to tell if payment was made.  In this case the user should use the orders transaction_id to check
  with the payment provider to determine if a payment was made and a refund is necessary.

```
Request
  Method:   PUT
  URL:      /orders/:ORDER_UUID/cancel

Response:
  Status:   200 OK   
  Body:     "{
              "id": "ORDER_UUID",
              "name": "CUSTOMER_NAME",
              "status": "STATUS",
              "request_id": "REQUEST_UUID",
              "transaction_id": "TRANSACTION_UUID"
              "created_at": "TIME_ORDER_WAS_MADE",
              "updated_at": "LAST_UPDATE_TIME",
              "order_items": [
                {
                  "item_id": "ITEM_UUID",
                  "quantity": NUMBER_TO_PURCHASE
                },
                ...
              }
            }"

Response:
  Status:   204 No Content
```

#### Usage

* you need to replace [ORDER_UUID] in the command below with one returned from the list of all orders

```console
curl -v -H "Accept: application/json" \
        -H "Content-type: application/json" \
        -X PUT -G http://localhost/orders/[ORDER_UUID]/cancel | jq
```

### Get list of sales by item

Gets a list of the sales for all items on sale with optional filtering, sorting and paging.
This list will include all items even those that are not in stock

#### Filters - optional

Query filters are given as url query parameters.  They have the form

```
'q[' + attribute '_' + predicate + ']=' value
```

where attribute is one of `name`,`price`,`sales` or `quantity` and the predicates are any of those listed
on the ransack site at https://github.com/activerecord-hackery/ransack#search-matchers

#### Sort order - optional

```
'q[s]' + attribute + '%20' + order
```

order can be `desc` or `asc`

#### Paging - optional

```
'page=' + number
```

```
Request
  Method:   GET
  URL:      /items

  Optional Filter
    QUERY:  q[attribute_predicate]=value
    SORT:   q[s]=attribute%20desc

Response:

  Headers:
            Current-Page: The page that was returned
            Page-Items:   Number of items per page
            Total-Pages:  Total number of pages
            Total-Count:  Total number of scores

  Body:     "[
              {
                "id": "ITEM_UUID",
                "name": "ITEMS_NAME",
                "price": PRICE_PER_ITEM,
                "quantity": NUMBER_OF_ITEMS_IN_STOCK
                "sales": REVENUE_FROM_ITEM_SALES,
                "created_at": "TIME_ITEM_WAS_ADDED",
                "updated_at": "LAST_UPDATE_TIME",
              }
              ...
            ]"
```
#### Usage

* Getting the first page of items whose name start with 'choc' in ascending alphabetic order.

```console
curl -v -H "Accept: application/json" \
        -H "Content-type: application/json" \
        -X GET -G http://localhost/sales \
        -d "page=1&q[name_start]=choc&q[s]=name%20asc" | jq
```
