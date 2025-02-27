
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(ca.ca_city, 'Unknown') AS city,
        coalesce(ca.ca_state, 'Unknown') AS state,
        0 AS level
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_customer_sk IS NOT NULL

    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(ca.ca_city, 'Unknown'),
        coalesce(ca.ca_state, 'Unknown'),
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)

SELECT
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.city,
    ch.state,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales,
    AVG(d.d_year) AS avg_order_year,
    SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(sr.sr_return_tax, 0)) AS total_store_returns,
    STRING_AGG(DISTINCT CONCAT(wp.wp_url, ' (', wp.wp_type, ')'), '; ') AS visited_web_pages
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN 
    store_returns sr ON ch.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    ch.level <= 2
GROUP BY 
    ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.city, ch.state
ORDER BY 
    total_web_sales DESC, total_web_returns ASC
LIMIT 100;
