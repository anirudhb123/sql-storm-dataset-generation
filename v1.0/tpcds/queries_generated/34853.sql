
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        1 AS level,
        NULL AS parent_store_sk
    FROM store
    WHERE s_store_id = 'S001'
    
    UNION ALL
    
    SELECT
        s_store_sk,
        s_store_name,
        sh.level + 1,
        sh.s_store_sk AS parent_store_sk
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE s.s_closed_date_sk IS NULL
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender IS NOT NULL
),
return_summary AS (
    SELECT
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        COUNT(DISTINCT sr_customer_sk) AS unique_customers
    FROM store_returns
    GROUP BY sr_store_sk
),
sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_sales_price) AS total_sales_value,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
final_summary AS (
    SELECT
        s.s_store_name,
        r.total_returns,
        r.total_return_amount,
        r.total_return_tax,
        r.unique_customers,
        ss.total_sales,
        ss.total_sales_value,
        ss.total_discount
    FROM return_summary r
    LEFT JOIN store s ON r.sr_store_sk = s.s_store_sk
    LEFT JOIN sales_summary ss ON s.s_store_sk = ss.ws_item_sk
    WHERE COALESCE(r.total_returns, 0) > 5
)
SELECT
    fs.s_store_name,
    fs.total_returns,
    fs.total_return_amount,
    fs.total_return_tax,
    fs.unique_customers,
    fs.total_sales,
    fs.total_sales_value,
    fs.total_discount,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.ca_city,
    ci.rn
FROM final_summary fs
JOIN customer_info ci ON ci.rn <= 100
ORDER BY fs.total_sales_value DESC, fs.s_store_name;
