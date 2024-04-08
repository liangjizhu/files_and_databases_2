-- Business way of life

-- Prepare client sales data for the last 12 months
WITH ClientSales AS (
    SELECT
        cl.barcode, 
        cl.orderdate AS sale_date, 
        TO_NUMBER(cl.quantity) AS quantity, -- Convert string quantity to a number
        cl.price,
        sl.cost
    FROM Client_Lines cl
    JOIN References r ON cl.barcode = r.barcode
    LEFT JOIN Supply_Lines sl ON r.barCode = sl.barCode
    WHERE cl.orderdate >= ADD_MONTHS(TRUNC(SYSDATE), -12)  -- Select sales from the last 12 months
),
-- Prepare data from anonymous sales
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
    -- Select sales from the last 12 months
    WHERE la.orderdate >= ADD_MONTHS(TRUNC(SYSDATE), -12)  
),
-- Combine client and anonymous sales to calculate monthly sales statistics
MonthlySales AS (
    SELECT
        cs.barcode, 
        TO_CHAR(cs.sale_date, 'YYYY-MM') AS sale_period,  -- Combine year and month for the sale period
        COUNT(DISTINCT cs.sale_date) AS number_of_purchases,
        SUM(cs.quantity) AS units_sold,
        SUM(cs.price * cs.quantity) AS total_income,
        SUM(cs.price * cs.quantity) - SUM(cs.cost * cs.quantity) AS total_benefit,
        ROW_NUMBER() OVER (
            PARTITION BY TO_CHAR(cs.sale_date, 'YYYY-MM')
            ORDER BY SUM(cs.quantity) DESC
        ) AS rank  -- Rank products by units sold in each period
    FROM (
        SELECT * FROM ClientSales
        UNION ALL
        SELECT * FROM AnonymSales
    ) cs
    GROUP BY cs.barcode, TO_CHAR(cs.sale_date, 'YYYY-MM')
)
-- Select the best-selling product for each period
SELECT
    sale_period, 
    barcode AS best_selling_reference, 
    number_of_purchases, 
    units_sold,
    total_income, 
    total_benefit
FROM MonthlySales
WHERE rank = 1  -- Choose top-ranked (best-selling) products
-- Order by recent periods first
ORDER BY sale_period DESC; 
