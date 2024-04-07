-- Bestsellers Geographic Report


-- in this query creation we select the tables:
-- products, references, client_lines and Lines_Anonym

-- subquery for sales made

-- Calculate total units sold for each varietal in the last year
WITH TotalUnitsSold AS (
    SELECT
		-- Select the varietal from the Products table
        p.varietal,
		 -- Sum the quantities sold in Client_Lines and Lines_Anonym
        SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS total_units 
	-- From the Products table
    FROM Products p
	-- Join with References to link products to sales
    LEFT JOIN References r ON p.product = r.product
	-- Join with Client_Lines to get sales data
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode
	-- Join with Lines_Anonym to get anonymous sales data
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode
	-- Filter sales from the last year  
    WHERE (cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))  
       OR (la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
    GROUP BY p.varietal  -- Group the results by varietal
), 
-- Aggregate sales data by country and varietal, also determine ranking of varietals within each country
SalesData AS (
    SELECT
		-- Determine the country of the sale
        CASE  
            WHEN cl.country IS NOT NULL THEN cl.country
            ELSE la.dliv_country
        END AS country,
		 -- Select the varietal
        p.varietal,
		-- Count the total number of distinct buyers 
        COUNT(DISTINCT cl.username) + COUNT(DISTINCT la.contact) AS total_buyers,
		-- Sum the total units sold  
        SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS total_units_sold,
		-- Calculate the total income  
        SUM(NVL(cl.price, 0) * TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.price, 0) * NVL(la.quantity, 0)) AS total_income,  
        -- Assign a row number to each varietal within the country, ordered by total units sold
		ROW_NUMBER() OVER (PARTITION BY CASE  
                              WHEN cl.country IS NOT NULL THEN cl.country
                              ELSE la.dliv_country
                           END ORDER BY SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) DESC) AS rn
    -- From the Products table
	FROM Products p
	-- Join with References to link products to sales
    LEFT JOIN References r ON p.product = r.product
	-- Join with Client_Lines for sales data within the last year  
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
	-- Join with Lines_Anonym for anonymous sales data within the last year  
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')  
    -- Group by country and varietal
	GROUP BY CASE  
                 WHEN cl.country IS NOT NULL THEN cl.country
                 ELSE la.dliv_country
             END, p.varietal
 	-- Include only records with sales
    HAVING COUNT(DISTINCT cl.username) + COUNT(DISTINCT la.contact) > 0 
), 
-- Determine the potential consumer countries for each varietal based on the 1% total units sold criterion
PotentialConsumerCountries AS (
    SELECT
        -- Select the varietal
		country_sales.varietal,
		-- Count the number of distinct countries where sales exceed 1% of the total units  
        COUNT(DISTINCT country) AS potential_consumer_countries  
    FROM (
        SELECT
			-- Select the varietal from Products
            p.varietal,
			-- Determine the country of the sale  
            CASE  
                WHEN cl.country IS NOT NULL THEN cl.country
                ELSE la.dliv_country
            END AS country,
			-- Sum the total units sold per country
            SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS country_total_units  
        -- From the Products table
		FROM Products p
		-- Join with References to link products to sales  
        LEFT JOIN References r ON p.product = r.product
		-- Join with Client_Lines for sales data  
        LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode
		-- Join with Lines_Anonym for anonymous sales data  
        LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode
		-- Filter sales from the last year  
        WHERE (cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))  
           OR (la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
        -- Group by varietal and country
		GROUP BY p.varietal, CASE  
                                WHEN cl.country IS NOT NULL THEN cl.country
                                ELSE la.dliv_country
                            END
    ) country_sales
	-- Join with TotalUnitsSold to access the total units per varietal
    JOIN TotalUnitsSold tus ON country_sales.varietal = tus.varietal
	-- Filter countries with sales exceeding 1% of total units  
    WHERE country_sales.country_total_units > 0.01 * tus.total_units
	-- Group the results by varietal  
    GROUP BY country_sales.varietal  
)
-- Final selection of best-selling varietal per country with associated statistics
SELECT
	-- Select the country
    sd.country,
 	-- Select the varietal  
    sd.varietal,
	-- Select the total number of buyers
    sd.total_buyers,
	-- Select the total units sold  
    sd.total_units_sold,
	-- Select the total income generated 
    sd.total_income,
	-- Calculate the average units sold per reference
    (SELECT AVG(total_quantity)  
     FROM (
		-- Convert the quantity to number and handle NULLs
		SELECT TO_NUMBER(NVL(cl.quantity, '0')) AS total_quantity
		-- From Client_Lines
		FROM Client_Lines cl
		-- Join with References to link sales to products  
		JOIN References r ON cl.barcode = r.barcode
		-- Join with Products to filter by varietal
		JOIN Products p ON r.product = p.product
		-- Filter sales of the specific varietal within the last year
		WHERE p.varietal = sd.varietal AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')  
		UNION ALL
		-- Select the quantity from Lines_Anonym
		SELECT la.quantity AS total_quantity
		 -- From Lines_Anonym  
		FROM Lines_Anonym la
		-- Join with References to link sales to products 
		JOIN References r ON la.barcode = r.barcode
		-- Join with Products to filter by varietal  
		JOIN Products p ON r.product = p.product
		-- Filter anonymous sales of the specific varietal within the last year 
		WHERE p.varietal = sd.varietal AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')  
     ) combined_quantities) AS avg_units_sold_per_reference,
	-- Select the number of potential consumer countries
    pcc.potential_consumer_countries,
	-- Concatenate the product names associated with the varietal  
    (SELECT LISTAGG(p.product, ', ') WITHIN GROUP (ORDER BY p.product)
	-- From the Products table  
     FROM Products p
	 -- Filter by the varietal
     WHERE p.varietal = sd.varietal
	  -- Limit to the first 1000 rows to prevent string overflow  
     FETCH FIRST 1000 ROWS ONLY) AS trademarks
-- From the aggregated sales data 
FROM SalesData sd
-- Join with PotentialConsumerCountries to include the count of potential consumer countries
JOIN PotentialConsumerCountries pcc ON sd.varietal = pcc.varietal
-- Filter to include only the top-selling varietal per country
WHERE sd.rn = 1
-- Order the results by total units sold in descending order  
ORDER BY sd.total_units_sold DESC;  

-- 226 rows selected