
WITH RECURSIVE profit_statistics AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        ps.total_profit,
        ps.total_sales
    FROM 
        profit_statistics ps
    JOIN 
        item i ON ps.ws_item_sk = i.i_item_sk
    WHERE 
        ps.total_profit > (SELECT AVG(total_profit) FROM profit_statistics)
),
customer_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    ca.ca_country,
    SUM(ti.total_profit) AS total_profit,
    AVG(ca.order_count) AS avg_order_count,
    COUNT(DISTINCT ca.c_customer_id) AS unique_customers
FROM 
    top_items ti
JOIN 
    customer_analysis ca ON ti.i_item_id IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws)
JOIN 
    customer_address cad ON ca.c_customer_id = cad.ca_address_id
GROUP BY 
    ca.ca_country
HAVING 
    total_profit > 1000
ORDER BY 
    total_profit DESC;
