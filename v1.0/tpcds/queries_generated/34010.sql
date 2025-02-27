
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cte.ws_sold_date_sk,
        ws_item_sk,
        cte.total_quantity + ws_quantity,
        cte.total_sales + ws_ext_sales_price
    FROM sales_cte cte
    JOIN web_sales ON cte.ws_item_sk = web_sales.ws_item_sk
    WHERE web_sales.ws_sold_date_sk < cte.ws_sold_date_sk
),
ranked_sales AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM sales_cte
),
customer_summary AS (
    SELECT 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN household_demographics ON hd_demo_sk = c_current_hdemo_sk
),
address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state) AS full_address
    FROM customer_address
    WHERE ca_state IS NOT NULL
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_quantity,
    cs.total_sales,
    ai.full_address
FROM ranked_sales rs
JOIN customer_summary cs ON cs.gender_rank <= 10
LEFT JOIN address_info ai ON cs.cd_demo_sk = ai.ca_address_sk
WHERE rs.total_sales > (SELECT AVG(total_sales) FROM ranked_sales)
ORDER BY rs.total_sales DESC;
