
WITH RECURSIVE inventory_levels AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_warehouse_sk, 
        inv_quantity_on_hand
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    UNION ALL
    SELECT 
        inv.inv_date_sk, 
        inv.inv_item_sk, 
        inv.inv_warehouse_sk, 
        inv.inv_quantity_on_hand
    FROM 
        inventory inv
    INNER JOIN 
        inventory_levels il ON inv.inv_date_sk = il.inv_date_sk - 1
    WHERE 
        inv.inv_item_sk = il.inv_item_sk
),
customer_analytics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT CASE WHEN ws.ws_net_profit < 0 THEN ws.ws_order_number END) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
seasonal_sales AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        SUM(ws.ws_net_profit) AS monthly_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        sale_month
),
address_summary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS state_profit
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca_state
)
SELECT 
    ca.ca_state,
    as.customer_count,
    as.state_profit,
    sa.sale_month,
    sa.monthly_profit,
    COALESCE(ca.customer_count, 0) AS customer_count_null_check,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS state_rank
FROM 
    customer_address ca
LEFT JOIN 
    address_summary as ON ca.ca_state = as.ca_state
LEFT JOIN 
    seasonal_sales sa ON sa.sale_month = EXTRACT(MONTH FROM CURRENT_DATE)
OUTER JOIN 
    customer_analytics cc ON cc.total_profit > 1000
WHERE 
    (as.state_profit IS NULL OR as.customer_count > 10)
ORDER BY 
    as.state_profit DESC, 
    sa.monthly_profit DESC;
