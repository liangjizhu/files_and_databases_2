# README

## Project Overview

This repository contains SQL scripts and PL/SQL packages for managing a database related to products, clients, orders, and providers. The scripts include table creation, data insertion, and various operations on the database.

## Repository Structure

* `bestseller_geographic_report.sql`: SQL script to generate a report on best-selling products by geographic location.
* `business_way_of_life.sql`: SQL script to calculate monthly sales statistics and identify best-selling products.
* `creation.sql`: SQL script for creating tables and defining constraints in the database.
* `load.sql`: SQL script for inserting data into the tables created by `creation.sql`.
* `operativity.sql`: PL/SQL package `caffeine` containing procedures for managing replacement orders and reporting on providers.
* `settings.sql`: SQL script for setting useful configurations and displaying table information.
* `trigger_2.sql`: SQL script for creating triggers to move purchases and posts to anonymous tables after a client is deleted.

## Usage

1. **Table Creation**: Run the `creation.sql` script to create the necessary tables and define constraints.
2. **Data Insertion**: Execute the `load.sql` script to insert data into the tables.
3. **Reports and Statistics**: Use the `bestseller_geographic_report.sql` and `business_way_of_life.sql` scripts to generate reports and calculate sales statistics.
4. **Operational Procedures**: Utilize the procedures in the `operativity.sql` script to manage replacement orders and generate provider reports.
5. **Triggers**: Implement the triggers defined in `trigger_2.sql` to handle data movement after client deletion.
6. **Settings**: Apply the configurations in `settings.sql` for useful settings and table information.

## Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Commit your changes with clear and concise messages.
4. Push your changes to your forked repository.
5. Create a pull request to the main repository.


