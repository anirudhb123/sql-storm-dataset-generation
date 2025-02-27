
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
widest_sales AS (
    SELECT 
        cs.cs_ship_customer_sk,
        cs.cs_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_quantity) AS quantity_sold
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_ship_customer_sk, cs.cs_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(ss.total_quantity, 0) AS web_total_quantity,
    COALESCE(ss.total_sales, 0) AS web_total_sales,
    COALESCE(ss.total_profit, 0) AS web_total_profit,
    COALESCE(w.order_count, 0) AS catalog_order_count,
    COALESCE(w.quantity_sold, 0) AS catalog_quantity_sold
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
LEFT JOIN 
    widest_sales w ON ci.c_customer_id = w.cs_ship_customer_sk
WHERE 
    ci.cd_gender = 'F'
    AND ci.cd_marital_status = 'M'
    AND ci.ca_state IN ('NY', 'CA')
ORDER BY 
    ci.full_name;
