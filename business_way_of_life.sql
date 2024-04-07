-- Business way of life
-- Prepare client sales data
WITH ClientSales AS (
    SELECT
        cl.barcode,
        cl.orderdate AS sale_date,
        TO_NUMBER(cl.quantity) AS quantity, -- Convert string quantity to a numeric value
        cl.price,
        sl.cost
    FROM Client_Lines cl
    JOIN References r ON cl.barcode = r.barcode
    LEFT JOIN Supply_Lines sl ON r.barCode = sl.barCode
    WHERE cl.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY') -- Filter sales in the last year
),
-- Prepare anonymous sales data
AnonymSales AS (
    SELECT
        la.barcode,
        la.orderdate AS sale_date,
        la.quantity,
        la.price,
        sl.cost
    FROM Lines_Anonym la
    JOIN References r ON la.barcode = r.barcode
    LEFT JOIN Supply_Lines sl ON r.barCode = sl.barCode
    WHERE la.orderdate BETWEEN ADD_MONTHS(TRUNC(SYSDATE, 'YY'), -12) AND TRUNC(SYSDATE, 'YY') -- Filter sales in the last year
),
-- Combine client and anonymous sales data, and compute monthly sales statistics
MonthlySales AS (
    SELECT
        cs.barcode,
        EXTRACT(YEAR FROM cs.sale_date) AS sale_year,
        EXTRACT(MONTH FROM cs.sale_date) AS sale_month,
        COUNT(DISTINCT cs.sale_date) AS number_of_purchases,
        SUM(cs.quantity) AS units_sold,
        SUM(cs.price * cs.quantity) AS total_income,
        SUM(cs.price * cs.quantity) - SUM(cs.cost * cs.quantity) AS total_benefit,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM cs.sale_date), EXTRACT(MONTH FROM cs.sale_date)
            ORDER BY SUM(cs.quantity) DESC
        ) AS rank
    FROM (
        SELECT * FROM ClientSales
        UNION ALL
        SELECT * FROM AnonymSales
    ) cs
    GROUP BY cs.barcode, EXTRACT(YEAR FROM cs.sale_date), EXTRACT(MONTH FROM cs.sale_date)
)
-- Select the best selling product of each month
SELECT
    sale_year,
    sale_month,
    barcode AS best_selling_reference,
    number_of_purchases,
    units_sold,
    total_income,
    total_benefit
FROM MonthlySales
WHERE rank = 1
ORDER BY sale_year DESC, sale_month DESC;

