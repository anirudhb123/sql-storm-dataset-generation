
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_web_site_sk
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_call_center_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_sales_price,
        ss_store_sk
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023)
),
aggregated_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY SUM(sd.ws_sales_price * sd.ws_quantity) DESC) AS sales_rank
    FROM sales_data sd
    GROUP BY sd.ws_sold_date_sk, sd.ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        agg.total_sales,
        agg.sales_rank
    FROM aggregated_sales agg
    JOIN item ON agg.ws_item_sk = item.i_item_sk
    WHERE agg.sales_rank <= 10
)
SELECT 
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ti.i_item_desc,
    ti.total_sales,
    COALESCE(ti.sales_rank, 0) AS item_sales_rank,
    CASE 
        WHEN ci.c_birth_day IS NOT NULL AND EXTRACT(DOW FROM CURRENT_DATE) IN (0, 6) THEN 'Birthday Weekend!'
        ELSE 'Regular Day'
    END AS special_message
FROM customer ci
LEFT JOIN top_items ti ON ci.c_customer_sk = (
    SELECT ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk IN (SELECT i_item_sk FROM top_items) 
    LIMIT 1
)
ORDER BY ti.total_sales DESC NULLS LAST;
