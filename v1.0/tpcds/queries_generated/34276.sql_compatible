
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        d.d_date_sk,
        ST.total_profit * 1.05 AS total_profit, 
        ST.total_orders,
        ST.level + 1
    FROM 
        sales_trends ST
    JOIN 
        date_dim d ON d.d_date_sk = ST.ws_sold_date_sk + 1
    WHERE 
        ST.level < 5
),
customer_promotions AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer_demographics cd
    JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10200 AND 10210
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(p.total_profit) AS average_profit,
    MAX(ct.total_orders) AS max_orders
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_promotions p ON c.c_current_cdemo_sk = p.cd_demo_sk
LEFT JOIN 
    (SELECT ws_bill_customer_sk, COUNT(ws_order_number) AS total_orders
     FROM web_sales
     GROUP BY ws_bill_customer_sk) ct ON c.c_customer_sk = ct.ws_bill_customer_sk
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    average_profit DESC;
