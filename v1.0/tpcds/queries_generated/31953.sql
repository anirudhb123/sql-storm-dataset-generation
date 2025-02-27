
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs.customer_sk,
        cs.net_profit,
        1 AS level
    FROM 
        catalog_sales cs
    WHERE 
        cs.sold_date_sk = (SELECT MAX(cs2.sold_date_sk) FROM catalog_sales cs2)
    
    UNION ALL
    
    SELECT 
        ws.ship_customer_sk,
        ws.net_profit,
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesHierarchy sh ON ws.bill_customer_sk = sh.customer_sk
    WHERE 
        ws.sold_date_sk = (SELECT MAX(ws2.sold_date_sk) FROM web_sales ws2)
)

SELECT 
    ca.city,
    SUM(COALESCE(sh.net_profit, 0)) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    STRING_AGG(DISTINCT c.c_email_address) AS customer_emails
FROM 
    SalesHierarchy sh
JOIN 
    customer c ON sh.customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.city
HAVING 
    SUM(COALESCE(sh.net_profit, 0)) > 10000
ORDER BY 
    total_net_profit DESC;

WITH DailySales AS (
    SELECT 
        d.d_date,
        SUM(COALESCE(ws.ws_sales_price, 0) - COALESCE(ws.ws_ext_discount_amt, 0)) AS daily_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY SUM(COALESCE(ws.ws_sales_price, 0) - COALESCE(ws.ws_ext_discount_amt, 0)) DESC) AS rn
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)

SELECT 
    DATE_FORMAT(daily.d_date, '%Y-%m-%d') AS sales_date,
    daily.daily_sales,
    CASE 
        WHEN daily.rn = 1 THEN 'Highest Sales'
        ELSE 'Regular'
    END AS category
FROM 
    DailySales daily
WHERE 
    daily.daily_sales IS NOT NULL
ORDER BY 
    daily.d_date DESC
LIMIT 10;

SELECT 
    s.s_store_name,
    SUM(ss.ss_net_profit) AS store_total_profit,
    AVG(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS avg_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    store s
LEFT JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    s.s_open_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    s.s_store_name
HAVING 
    AVG(COALESCE(ss.ss_net_paid_inc_tax, 0)) > 50
ORDER BY 
    store_total_profit DESC
LIMIT 5;
