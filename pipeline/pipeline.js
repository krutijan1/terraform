'use strict';
const host = process.env.HOST || false
const request = require('request');
const elasticsearch = require('elasticsearch');
const csv = require('fast-csv');
const path = require('path');

const log = console.log.bind(console);
const client = new elasticsearch.Client({
  requestTimeout: 300000,
  host
});

const datasetPath = path.join('dataset', 'titanic.csv');
const options = { 'headers': true };
const myindex = 'titanic'

if (host === false) {
  log('Error no host set as ENV var')
  return false;
}

async function createIndex() {
  log('creating index ...')
  await client.indices.create({ index: myindex });
  log('successfully created ElasticSearch index: %s', myindex);
}

function readDataSet() {
  return new Promise(function (resolve, reject) {
    const records = [];
    csv.fromPath(datasetPath, options)
      .on('data', function (record) {
        records.push(record);
      })
      .on('error', function (error) {
        reject(error);
      })
      .on('end', function () {
        resolve(records);
      });
  })
}

function bulkImport(records) {
  const bulk_request = [];
  for (let i = 0; i < records.length; i++) {
    bulk_request.push({ index: { _index: myindex, _type: '_doc', _id: records[i].PassengerId } });
    bulk_request.push(records[i]);
  }
  log('Bulk inserting records: ', JSON.stringify(bulk_request));
  return client.bulk({
    body: bulk_request
  });
}

function waitForIndexing() {
  log('Wait for indexing...');
  return new Promise(function (resolve) {
    setTimeout(resolve, 10000);
  });
}

function addToIndex() {
  log('creating index pattern on kibana for %s...', myindex)
  return new Promise(function (resolve, reject) {
    const kibanaUrl = host + '/.kibana/doc/index-pattern:' + myindex;
    request.post(
      kibanaUrl,
      { json: { 'type': 'index-pattern', 'index-pattern': { 'title': myindex + '*', 'timeFieldName': '' } } },
      function (error, response, body) {
        if(error) {
          return reject(error)
        }
        log(body)
        return resolve(body);
      }
    );
  });
}

function closeConnection() {
  client.close();
}

function showInfo() {
  log('go to: %s/_plugin/kibana/app/kibana#/management/kibana/index?_g=()', host)
}

async function execute() {
    await createIndex();
    await addToIndex();
    await waitForIndexing();
    const records = await readDataSet();
    await bulkImport(records);
    await closeConnection();
    return showInfo();
}

execute().then().catch(e => log(e))
