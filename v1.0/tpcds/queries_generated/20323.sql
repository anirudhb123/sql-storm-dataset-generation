
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_net_paid_inc_tax > 0
        AND ws.ws_quantity BETWEEN 1 AND 100
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_paid) AS total_spent,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM 
        customer c
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        AVG(cs.cs_quantity) > 2 AND SUM(cs.cs_net_paid) > 1000
),
HighPerformingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    ca.ca_address_id,
    cs.c_customer_id,
    ci.total_orders,
    ci.total_spent,
    COALESCE(hp.total_profit, 0) AS total_item_profit,
    COALESCE(hp.order_count, 0) AS item_order_count
FROM 
    customer_address ca
LEFT JOIN 
    customer cs ON cs.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerStats ci ON ci.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    HighPerformingItems hp ON hp.ws_item_sk = ci.avg_quantity 
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND (hp.total_profit IS NULL OR hp.total_profit > 100)
ORDER BY 
    ci.total_spent DESC, 
    ci.total_orders DESC
FETCH FIRST 100 ROWS ONLY;
