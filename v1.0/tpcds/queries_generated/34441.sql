
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(DISTINCT ws_order_number) > 5
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state = 'CA'
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.full_address,
    cc.total_orders,
    COALESCE(SUM(CASE WHEN sr.returned_date_sk IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_returns,
    cs.total_net_profit,
    RANK() OVER (ORDER BY SUM(COALESCE(sr.returned_qty, 0)) DESC) AS returns_rank
FROM 
    customer c
LEFT JOIN 
    customer_analysis cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN 
    address_info ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    sales_cte cs ON c.c_customer_sk = cs.ws_item_sk
WHERE 
    cc.total_orders IS NOT NULL 
    AND (cc.total_spent > 1000 OR cc.avg_purchase_estimate IS NULL)
GROUP BY 
    c.c_first_name, c.c_last_name, ca.full_address, cc.total_orders, cs.total_net_profit
HAVING 
    total_returns > 0 OR CS.total_net_profit > 500
ORDER BY 
    total_returns DESC, total_spent DESC;
