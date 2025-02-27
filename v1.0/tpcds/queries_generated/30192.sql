
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name
    HAVING 
        SUM(ws.ws_net_profit) > 100000
),
FilteredSales AS (
    SELECT 
        ws.ws_order_number,
        c.c_first_name,
        c.c_last_name,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        d.d_date AS sale_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sold_date_sk DESC) AS recent_sale_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_net_profit > 50
)
SELECT 
    sh.web_name,
    COUNT(DISTINCT ss.ws_order_number) AS order_count,
    MAX(ss.ws_net_profit) AS max_profit,
    AVG(ss.ws_net_profit) AS avg_profit,
    MAX(ss.sale_date) AS latest_sale_date
FROM 
    SalesHierarchy sh
LEFT JOIN 
    FilteredSales ss ON sh.rank <= 10 AND ss.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_holiday = 'Y')
GROUP BY 
    sh.web_name
ORDER BY 
    avg_profit DESC
LIMIT 5
UNION ALL
SELECT 
    'Total Count' AS web_name,
    COUNT(*) AS order_count,
    NULL AS max_profit,
    AVG(ss.ws_net_profit) AS avg_profit,
    NULL AS latest_sale_date
FROM 
    FilteredSales ss
WHERE ss.recent_sale_rank = 1;
