# GRAX Signals UI

## Setup
Run postgres in the background and `createdb signals_ui_development`

```
bundle install
rake db:migrate
bin/rails assets:precompile
bin/rails server
```

## Generate Scores

```
rake scores:generate
```

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
