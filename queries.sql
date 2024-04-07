-- Bestsellers Geographic Report
-- 1. country -> origins
-- 2. varietal -> Varietals
-- 3. buyer_id -> customers
SELECT origins, Varietals, COUNT(DISTINCT customers) AS total_buyers, 
       SUM(quantity) AS total_units_sold, SUM(sales_amount) AS total_income, 
       AVG(quantity) AS avg_units_sold_per_reference, 
       COUNT(DISTINCT case when quantity > total_units_sold * 0.01 then origins end) AS potential_consumer_countries,
       trademark
FROM sales
JOIN products ON sales.product_id = products.id
JOIN locations ON sales.location_id = locations.id
WHERE sales.date BETWEEN DATE 'last_year_start' AND DATE 'last_year_end'
GROUP BY origins, Varietals, trademark
ORDER BY total_buyers DESC;
