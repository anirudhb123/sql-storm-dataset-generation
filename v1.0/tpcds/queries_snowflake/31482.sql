
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
    WHERE 
        cd.cd_purchase_estimate > sh.cd_purchase_estimate
),
item_sales_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10001 AND 20001
    GROUP BY 
        i.i_item_sk
),
returns_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    sh.cd_marital_status,
    sh.cd_credit_rating,
    COALESCE(iss.total_sales, 0) AS total_sales,
    COALESCE(rs.total_returned, 0) AS total_returned,
    (COALESCE(iss.total_sales, 0) - COALESCE(rs.total_returned, 0)) AS net_sales
FROM 
    sales_hierarchy sh
LEFT JOIN 
    item_sales_summary iss ON sh.c_customer_sk = iss.i_item_sk
LEFT JOIN 
    returns_summary rs ON iss.i_item_sk = rs.sr_item_sk
WHERE 
    sh.cd_gender = 'F'
ORDER BY 
    net_sales DESC
LIMIT 100;
