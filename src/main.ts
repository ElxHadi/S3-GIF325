import fs from "fs";
import path from "path";
import { parse } from "csv-parse";
import knex from "../knex";

const csvPath = path.resolve(__dirname, "../../data/posseder.csv");

async function importCSV() {
    const parser = fs
        .createReadStream(csvPath)
        .pipe(parse({ columns: true, skip_empty_lines: true }));

    for await (const record of parser) {
        await knex("posseder").insert({
            cip: record.cip,
            id_statut: record.id_statut
        });
    }

    console.log("CSV imports completed.");
}

importCSV()
    .catch((error) => {
        console.error("Error importing CSV:", error);
    })
    .finally(() => {
        knex.destroy();
    });
