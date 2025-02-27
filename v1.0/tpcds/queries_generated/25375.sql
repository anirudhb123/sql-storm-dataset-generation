
WITH AddressInfo AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.city, ca.state
),
SalesSummary AS (
    SELECT 
        s.s_store_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_name
),
WebSalesSummary AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_transactions,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ws.ws_ext_sales_price) AS avg_web_sales_price
    FROM 
        web_site ws
    JOIN 
        web_sales w ON ws.web_site_sk = w.ws_web_site_sk
    GROUP BY 
        ws.web_site_id
)

SELECT 
    ai.city,
    ai.state,
    ai.customer_count,
    ai.customers,
    ss.s_store_name,
    ss.total_transactions,
    ss.total_sales,
    ss.avg_sales_price,
    wws.total_web_transactions,
    wws.total_web_sales,
    wws.avg_web_sales_price
FROM 
    AddressInfo ai
JOIN 
    SalesSummary ss ON ai.city = ss.s_store_name -- Assuming a join condition in example
JOIN 
    WebSalesSummary wws ON ai.city = wws.web_site_id -- Assuming a join condition in example
ORDER BY 
    ai.state, ai.city;
