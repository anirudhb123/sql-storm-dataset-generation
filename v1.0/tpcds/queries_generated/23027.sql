
WITH RecursiveSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), 
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(COUNT(DISTINCT cr.cr_item_sk), 0) AS return_count
    FROM 
        customer_address ca
    LEFT JOIN 
        store_returns cr ON ca.ca_address_sk = cr.sr_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
SalesWithReturns AS (
    SELECT 
        r.customer_id,
        r.total_profit,
        a.ca_city,
        a.return_count,
        RANK() OVER (PARTITION BY a.ca_state ORDER BY r.total_profit DESC) AS state_rank
    FROM 
        RecursiveSales r
    JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = r.c_customer_sk)
    JOIN 
        AddressInfo a ON a.ca_address_sk = ca.ca_address_sk
)
SELECT 
    s.ca_city,
    SUM(s.total_profit) AS total_sales,
    AVG(s.return_count) AS avg_returns,
    COUNT(s.customer_id) AS customer_count,
    STRING_AGG(CONCAT(s.customer_id, ': ', s.total_profit), ', ') AS profitable_customers
FROM 
    SalesWithReturns s
WHERE 
    s.state_rank <= 10
GROUP BY 
    s.ca_city
HAVING 
    SUM(s.total_profit) > 10000 OR AVG(s.return_count) IS NULL
ORDER BY 
    total_sales DESC;
