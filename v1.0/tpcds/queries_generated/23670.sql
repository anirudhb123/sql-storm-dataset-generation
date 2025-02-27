
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS profit_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_sk) AS total_quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) OVER (PARTITION BY ws.web_site_sk) AS unique_customers
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0 AND ws.ws_quantity IS NOT NULL
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
SalesInfo AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS num_customers
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(s.total_net_profit, 0) AS store_net_profit,
    COALESCE(s.num_customers, 0) AS store_customers,
    COUNT(DISTINCT r.ws_order_number) AS total_orders,
    SUM(r.ws_quantity) AS total_quantity,
    AVG(r.ws_sales_price) FILTER (WHERE r.profit_rank <= 5) AS avg_top_profit_sales_price,
    CASE 
        WHEN COUNT(DISTINCT r.ws_order_number) > 1000 THEN 'High Activity'
        WHEN COUNT(DISTINCT r.ws_order_number) BETWEEN 500 AND 1000 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    AddressInfo a
LEFT JOIN 
    SalesInfo s ON a.customer_count > 5
LEFT JOIN 
    RankedSales r ON a.customer_count < 100
GROUP BY 
    a.ca_city, a.ca_state, s.total_net_profit, s.num_customers
HAVING 
    COUNT(DISTINCT r.ws_order_number) > 10 OR 
    MAX(r.total_quantity) > 50
ORDER BY 
    store_net_profit DESC NULLS LAST;
