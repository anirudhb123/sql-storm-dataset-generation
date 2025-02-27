
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 100 AND 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        ag.total_net_profit,
        ag.total_orders
    FROM 
        item i
    JOIN 
        AggregateSales ag ON i.i_item_sk = ag.ws_item_sk
    WHERE 
        ag.total_net_profit > (SELECT AVG(total_net_profit) FROM AggregateSales)
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
    ARRAY_AGG(DISTINCT t.si_error_code) FILTER (WHERE t.si_error_code IS NOT NULL) AS error_codes,
    STRING_AGG(DISTINCT CASE WHEN c.c_birth_year IS NOT NULL THEN CONCAT(c.c_first_name, ' ', c.c_last_name) END, ', ') AS active_customers
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    (SELECT cr_item_sk, cr_reason_sk, cr_order_number, sr_return_quantity, sr_return_amt
     FROM catalog_returns 
     WHERE cr_return_quantity > 0) t ON ws.ws_item_sk = t.cr_item_sk
JOIN 
    TopSellingItems tsi ON ws.ws_item_sk = tsi.ws_item_sk
GROUP BY 
    a.ca_city
HAVING 
    total_profit > 1000 AND 
    COUNT(DISTINCT c.c_customer_id) > 20
ORDER BY 
    unique_customers DESC, total_profit ASC
LIMIT 10;
