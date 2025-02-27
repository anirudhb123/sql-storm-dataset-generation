
WITH RECURSIVE customer_growth AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COUNT(1) OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_count,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_customer_sk) AS marital_row
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
),
item_sales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sold, 
           CASE 
               WHEN SUM(ws.ws_sales_price) IS NULL THEN 'Unknown'
               ELSE 'Known'
           END AS sales_status
    FROM web_sales ws 
    WHERE ws.ws_sales_price IS NOT NULL OR (ws.ws_item_sk IS NOT NULL AND ws.ws_bill_customer_sk IS NOT NULL)
    GROUP BY ws.ws_item_sk
),
null_count AS (
    SELECT COUNT(*) AS null_records 
    FROM store_returns sr 
    WHERE sr.sr_return_quantity IS NULL AND sr.sr_return_amt IS NULL
),
valid_sales AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, 
           COALESCE(total_sold, 0) AS total_sales,
           CASE WHEN null_count.null_records > 0 THEN 'Contains NULL' ELSE 'No NULLs' END AS null_status
    FROM item i
    LEFT JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
    CROSS JOIN null_count
)
SELECT cg.c_first_name, cg.c_last_name, cg.cd_gender, cg.cd_marital_status,
       vs.i_item_id, vs.i_product_name, vs.total_sales, vs.null_status, 
       ROW_NUMBER() OVER (PARTITION BY cg.cd_gender ORDER BY vs.total_sales DESC) AS sales_rank,
       'Year ' || CAST(EXTRACT(YEAR FROM CURRENT_DATE) AS CHAR) || ' Analysis' AS report_year
FROM customer_growth cg
JOIN valid_sales vs ON (cg.gender_count > 10 AND vs.total_sales > 0)
WHERE (cg.marital_row <= 5 OR cg.cd_gender = 'F')
AND (cg.c_first_name LIKE 'A%' OR cg.c_last_name LIKE 'Z%')
ORDER BY cg.cd_gender, vs.total_sales DESC;
