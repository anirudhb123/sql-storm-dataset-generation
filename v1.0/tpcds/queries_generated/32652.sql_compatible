
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk, ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    ci.c_last_name,
    ci.c_first_name,
    ci.ca_city,
    ci.ca_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_net_paid) AS total_spent,
    COALESCE(SUM(wb.ws_sales_price), 0) AS total_web_sales,
    COALESCE(AVG(is.total_sales_price), 0) AS avg_item_price,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS customer_rank
FROM 
    customer_info ci
LEFT JOIN 
    store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales wb ON ci.c_customer_sk = wb.ws_bill_customer_sk
LEFT JOIN 
    item_sales is ON wb.ws_item_sk = is.i_item_sk
WHERE 
    ci.city_rank <= 5
GROUP BY 
    ci.c_last_name, ci.c_first_name, ci.ca_city, ci.ca_state
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_spent DESC;
