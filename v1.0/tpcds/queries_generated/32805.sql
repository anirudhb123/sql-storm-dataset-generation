
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) + c.total_quantity, SUM(ws_net_paid) + c.total_sales
    FROM web_sales w
    JOIN SalesCTE c ON w.ws_item_sk = c.ws_item_sk AND w.ws_sold_date_sk = c.ws_sold_date_sk + 1
    GROUP BY w.ws_sold_date_sk, w.ws_item_sk
),
SalesSummary AS (
    SELECT 
        d.d_year,
        i.i_item_id,
        COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(s.total_sales), 0) AS total_sales_amount,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        COUNT(DISTINCT ws.web_site_id) AS unique_websites
    FROM date_dim d
    LEFT JOIN SalesCTE s ON d.d_date_sk = s.ws_sold_date_sk
    LEFT JOIN item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON s.ws_item_sk = ws.ws_item_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, i.i_item_id
)
SELECT 
    d.d_year,
    i.i_item_id,
    standardize.format(float(total_sales_amount), 'USD') AS formatted_sales,
    average.quantity_sold AS average_quantity
FROM SalesSummary
JOIN item i ON i.i_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT d.d_year, i.i_item_id, AVG(total_quantity_sold) AS average_quantity
    FROM SalesSummary
    GROUP BY d.d_year, i.i_item_id
) AS average ON SalesSummary.d_year = average.d_year AND SalesSummary.i_item_id = average.i_item_id
WHERE total_quantity_sold IS NOT NULL
ORDER BY d.d_year, total_sales_amount DESC;
