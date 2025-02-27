
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS row_num
    FROM web_sales
    GROUP BY ws_item_sk, ws_order_number
),
high_sales AS (
    SELECT 
        hs.ws_item_sk,
        hs.total_quantity,
        hs.total_sales,
        CASE
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 5 THEN 'Low Income'
            ELSE 'High Income'
        END AS income_band_desc
    FROM sales_summary hs
    LEFT JOIN household_demographics hd ON hs.ws_item_sk = hd.hd_demo_sk
    WHERE hs.total_sales > (
        SELECT AVG(total_sales)
        FROM sales_summary
    )
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS customer_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    st.s_store_name,
    si.ws_item_sk,
    ht.total_quantity,
    ht.total_sales,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city
FROM high_sales ht
JOIN store_sales si ON ht.ws_item_sk = si.ss_item_sk
JOIN store st ON si.ss_store_sk = st.s_store_sk
JOIN customer_info ci ON si.ss_customer_sk = ci.c_customer_sk
WHERE ci.customer_rank = 1
ORDER BY ht.total_sales DESC
LIMIT 100;
