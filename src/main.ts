import fs from 'fs';
import path from 'path';
import {parse} from 'csv-parse';
import knex from '../knex';

const csvFilePath = path.resolve(__dirname, '../../data/statut.csv');

async function importCSV() {
  const parser = fs.createReadStream(csvFilePath).pipe(parse({ columns: true }));

  for await (const record of parser) {
    await knex('statut').insert({
      nom_statut: record.nom_statut,
    });
  }

  console.log('CSV import completed.');
}

importCSV()
  .catch(error => {
    console.error('Error importing CSV:', error);
  })
  .finally(() => {
    knex.destroy();
  });
