import fs from "fs";
import path from "path";
import { parse } from "csv-parse";
import knex from "../knex";

const csvPath = path.resolve(__dirname, "../../data/csv/reservation.csv");

async function importCSV() {
    const parser = fs
        .createReadStream(csvPath)
        .pipe(parse({ columns: true, skip_empty_lines: true }));

    for await (const record of parser) {
        await knex("reserver").insert({
            date_debut: record.date_debut,
            date_fin: record.date_fin,
            description: record.description,
            pavillon: record.pavillon,
            numero: record.numero,
            cip: record.cip,
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
