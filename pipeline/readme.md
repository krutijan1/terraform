# Pipeline to insert data into elastic search instance

## Installation

- Make sure you've installed node on your OS.
- Make sure elastic search uses kibana.
- Clone the repository and run `npm install` command inside pipeline folder.

## Setting host for elastic search

Set host pointing for deployed instance of elastic search e.g:

```
export HOST=localhost
```

## Running elastic search inserting

```
node pipeline.js
```
