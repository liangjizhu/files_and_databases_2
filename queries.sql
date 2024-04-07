-- Bestsellers Geographic Report


-- in this query creation we select the tables:
-- products, references, client_lines and Lines_Anonym

-- subquery for sales made
WITH SalesData AS (
    SELECT
		-- country
        p.origin AS country,
        p.varietal,
        COUNT(DISTINCT cl.username) + COUNT(DISTINCT la.contact) AS total_buyers,
        SUM(TO_NUMBER(cl.quantity)) + SUM(la.quantity) AS total_units_sold,
        SUM(cl.price * TO_NUMBER(cl.quantity)) + SUM(la.price * la.quantity) AS total_income,
        AVG(TO_NUMBER(cl.quantity)) + AVG(la.quantity) AS avg_units_sold_per_reference
    FROM Products p
    LEFT JOIN References r ON p.product = r.product
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
    GROUP BY p.origin, p.varietal
), 
PotentialCountries AS (
    SELECT 
        p.varietal,
        COUNT(DISTINCT p.origin) AS potential_consumer_countries
    FROM Products p
    WHERE p.product IN (
        SELECT r.product
        FROM References r
        WHERE r.barcode IN (
            SELECT barcode FROM Client_Lines
            WHERE orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
            GROUP BY barcode
            HAVING SUM(TO_NUMBER(quantity)) > 0.01 * (SELECT SUM(quantity) FROM Lines_Anonym WHERE orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
            UNION ALL
            SELECT barcode FROM Lines_Anonym
            WHERE orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
            GROUP BY barcode
            HAVING SUM(quantity) > 0.01 * (SELECT SUM(quantity) FROM Client_Lines WHERE orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
        )
    )
    GROUP BY p.varietal
) SELECT
    sd.country,
    sd.varietal,
    sd.total_buyers,
    sd.total_units_sold,
    sd.total_income,
    sd.avg_units_sold_per_reference,
    pc.potential_consumer_countries,
    (SELECT LISTAGG(product, ', ') WITHIN GROUP (ORDER BY product)
     FROM Products p
     WHERE p.varietal = sd.varietal
     FETCH FIRST 100 ROWS ONLY) AS trademarks
FROM SalesData sd
JOIN PotentialCountries pc ON sd.varietal = pc.varietal
ORDER BY sd.total_buyers DESC;

-- 64 rows selected

WITH SalesData AS (
    SELECT
        CASE
            WHEN cl.country IS NOT NULL THEN cl.country
            ELSE la.dliv_country
        END AS country,
        p.varietal,
        COUNT(DISTINCT cl.username) + COUNT(DISTINCT la.contact) AS total_buyers,
        SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS total_units_sold,
        SUM(NVL(cl.price, 0) * TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.price, 0) * NVL(la.quantity, 0)) AS total_income
    FROM Products p
    LEFT JOIN References r ON p.product = r.product
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
    GROUP BY CASE
                 WHEN cl.country IS NOT NULL THEN cl.country
                 ELSE la.dliv_country
             END, p.varietal
), PotentialConsumerCountries AS (
    SELECT
        p.varietal,
        COUNT(DISTINCT CASE
                         WHEN cl.country IS NOT NULL THEN cl.country
                         ELSE la.dliv_country
                       END) AS potential_consumer_countries
    FROM Products p
    LEFT JOIN References r ON p.product = r.product
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode
    WHERE (cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
       OR (la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
    GROUP BY p.varietal
)
SELECT
    sd.country,
    sd.varietal,
    sd.total_buyers,
    sd.total_units_sold,
    sd.total_income,
    (SELECT AVG(total_quantity)
     FROM (
         SELECT TO_NUMBER(NVL(cl.quantity, '0')) AS total_quantity
         FROM Client_Lines cl
         JOIN References r ON cl.barcode = r.barcode
         JOIN Products p ON r.product = p.product
         WHERE p.varietal = sd.varietal AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
         UNION ALL
         SELECT la.quantity AS total_quantity
         FROM Lines_Anonym la
         JOIN References r ON la.barcode = r.barcode
         JOIN Products p ON r.product = p.product
         WHERE p.varietal = sd.varietal AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
     ) combined_quantities) AS avg_units_sold_per_reference,
    pcc.potential_consumer_countries,
    (SELECT LISTAGG(p.product, ', ') WITHIN GROUP (ORDER BY p.product)
     FROM Products p
     WHERE p.varietal = sd.varietal
     FETCH FIRST 1000 ROWS ONLY) AS trademarks
FROM SalesData sd
JOIN PotentialConsumerCountries pcc ON sd.varietal = pcc.varietal
ORDER BY sd.total_buyers DESC;

-- 

WITH TotalUnitsSold AS (
    SELECT
        p.varietal,
        SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS total_units
    FROM Products p
    LEFT JOIN References r ON p.product = r.product
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode
    WHERE (cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
       OR (la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
    GROUP BY p.varietal
), SalesData AS (
    SELECT
        CASE
            WHEN cl.country IS NOT NULL THEN cl.country
            ELSE la.dliv_country
        END AS country,
        p.varietal,
        COUNT(DISTINCT cl.username) + COUNT(DISTINCT la.contact) AS total_buyers,
        SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS total_units_sold,
        SUM(NVL(cl.price, 0) * TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.price, 0) * NVL(la.quantity, 0)) AS total_income
    FROM Products p
    LEFT JOIN References r ON p.product = r.product
    LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
    LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
    GROUP BY CASE
                 WHEN cl.country IS NOT NULL THEN cl.country
                 ELSE la.dliv_country
             END, p.varietal
    HAVING COUNT(DISTINCT cl.username) + COUNT(DISTINCT la.contact) > 0
), PotentialConsumerCountries AS (
    SELECT
        cs.varietal,
        COUNT(DISTINCT cs.country) AS potential_consumer_countries
    FROM (
        SELECT
            p.varietal,
            CASE
                WHEN cl.country IS NOT NULL THEN cl.country
                ELSE la.dliv_country
            END AS country,
            SUM(TO_NUMBER(NVL(cl.quantity, '0'))) + SUM(NVL(la.quantity, 0)) AS country_total_units
        FROM Products p
        LEFT JOIN References r ON p.product = r.product
        LEFT JOIN Client_Lines cl ON r.barCode = cl.barcode
        LEFT JOIN Lines_Anonym la ON r.barCode = la.barcode
        WHERE (cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
           OR (la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY'))
        GROUP BY p.varietal, CASE
                                WHEN cl.country IS NOT NULL THEN cl.country
                                ELSE la.dliv_country
                             END
    ) cs
    JOIN TotalUnitsSold tus ON cs.varietal = tus.varietal
    WHERE cs.country_total_units > 0.01 * tus.total_units
    GROUP BY cs.varietal
)
SELECT
    sd.country,
    sd.varietal,
    sd.total_buyers,
    sd.total_units_sold,
    sd.total_income,
    (SELECT AVG(total_quantity)
     FROM (
         SELECT TO_NUMBER(NVL(cl.quantity, '0')) AS total_quantity
         FROM Client_Lines cl
         JOIN References r ON cl.barcode = r.barcode
         JOIN Products p ON r.product = p.product
         WHERE p.varietal = sd.varietal AND cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
         UNION ALL
         SELECT la.quantity AS total_quantity
         FROM Lines_Anonym la
         JOIN References r ON la.barcode = r.barcode
         JOIN Products p ON r.product = p.product
         WHERE p.varietal = sd.varietal AND la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY')
     ) combined_quantities) AS avg_units_sold_per_reference,
    pcc.potential_consumer_countries,
    (SELECT LISTAGG(p.product, ', ') WITHIN GROUP (ORDER BY p.product)
     FROM Products p
     WHERE p.varietal = sd.varietal
     FETCH FIRST 1000 ROWS ONLY) AS trademarks
FROM SalesData sd
JOIN PotentialConsumerCountries pcc ON sd.varietal = pcc.varietal
ORDER BY sd.total_units_sold DESC;

-- 3784 rows selected
