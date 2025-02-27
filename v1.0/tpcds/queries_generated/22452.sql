
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_street_number, ca_street_name, ca_city, ca_state, ca_zip,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_state IS NOT NULL
),
MaxReturns AS (
    SELECT wy.year AS return_year, 
           COUNT(DISTINCT wr.returning_customer_sk) AS returning_customers,
           SUM(wr.return_quantity) AS total_returned
    FROM web_returns wr
    JOIN (SELECT EXTRACT(YEAR FROM d_date) AS year
          FROM date_dim
          GROUP BY EXTRACT(YEAR FROM d_date)) AS wy
    ON wr.w_returned_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim
        WHERE d_year = wy.year
    )
    GROUP BY wy.year
),
IncomeBandStats AS (
    SELECT ib_income_band_sk,
           SUM(hd_dep_count) AS total_deps,
           AVG(hd_vehicle_count) AS avg_vehicle_count
    FROM household_demographics h
    JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    WHERE h.hd_buy_potential != 'None'
    GROUP BY ib_income_band_sk
),
ItemSales AS (
    SELECT i.i_item_id,
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (6, 7)
    )
    GROUP BY i.i_item_id
)
SELECT 
    addr.ca_street_number || ' ' || addr.ca_street_name AS full_address,
    addr.ca_city, 
    addr.ca_state,
    COALESCE(sales.total_sales, 0) AS total_sales,
    customer_stats.returning_customers,
    income_stats.total_deps,
    income_stats.avg_vehicle_count,
    CASE 
        WHEN sales.sales_rank <= 10 THEN 'Top Seller'
        WHEN sales.sales_rank BETWEEN 11 AND 20 THEN 'Mid Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM AddressCTE addr
LEFT JOIN ItemSales sales ON addr.ca_address_sk = sales.i_item_id
LEFT JOIN MaxReturns customer_stats ON (EXTRACT(YEAR FROM CURRENT_DATE) = customer_stats.return_year)
LEFT JOIN IncomeBandStats income_stats ON addr.ca_addr_sk = income_stats.ib_income_band_sk
WHERE addr.rn <= 5
ORDER BY addr.ca_state, total_sales DESC NULLS LAST
LIMIT 100;
