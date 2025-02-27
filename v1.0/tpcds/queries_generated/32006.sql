
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452226 AND 2452226 + 30
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_sales_price) + SUM(ws_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN web_sales ws ON cs.cs_item_sk = ws.ws_item_sk
    WHERE cs.cs_sold_date_sk <= (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY cs_item_sk
),
TopSales AS (
    SELECT i.i_item_id, i.i_item_desc, c.c_first_name, c.c_last_name, s.s_store_name, d.d_year,
           RANK() OVER (PARTITION BY d.d_year ORDER BY total_sales DESC) AS sales_rank
    FROM SalesCTE
    JOIN item i ON SalesCTE.ws_item_sk = i.i_item_sk
    JOIN customer c ON i.i_item_sk = c.c_current_cdemo_sk
    JOIN store s ON c.c_current_addr_sk = s.s_store_sk
    JOIN date_dim d ON s.s_store_sk = d.d_date_sk
    WHERE sales_rank <= 10
)
SELECT t.i_item_id, t.i_item_desc, COALESCE(c.ca_country, 'Unknown') AS country,
       COUNT(DISTINCT c.c_customer_sk) AS total_customers,
       SUM(CASE WHEN t.sales_rank <= 5 THEN t.total_sales ELSE 0 END) AS top_sales,
       AVG(ws_ext_sales_price) AS avg_price
FROM TopSales t
LEFT JOIN customer_address c ON t.c_current_addr_sk = c.ca_address_sk
LEFT JOIN web_sales ws ON t.i_item_id = ws.ws_item_sk
WHERE (c.ca_country IS NULL OR c.ca_country <> 'USA')
  AND (t.total_sales > 1000 OR t.total_sales < 100)
GROUP BY t.i_item_id, t.i_item_desc, c.ca_country
ORDER BY avg_price DESC
LIMIT 50;
