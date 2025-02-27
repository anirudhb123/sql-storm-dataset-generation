
WITH RankedWebSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.web_site_sk
),
StoreSalesData AS (
    SELECT 
        ss.ss_store_sk,
        AVG(ss.ss_net_paid_inc_tax) AS avg_sales,
        MAX(ss.ss_net_profit) AS max_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    w.w_warehouse_id, 
    COALESCE(SUM(CASE WHEN rs.rank = 1 THEN rs.total_profit END), 0) AS top_website_profit,
    COALESCE(SUM(ss.avg_sales), 0) AS average_store_sales,
    COALESCE(SUM(ss.max_profit), 0) AS max_store_profit
FROM 
    warehouse w
LEFT JOIN 
    RankedWebSales rs ON w.w_warehouse_sk = rs.web_site_sk
JOIN 
    StoreSalesData ss ON w.w_warehouse_sk = ss.ss_store_sk 
GROUP BY 
    w.w_warehouse_id
HAVING 
    top_website_profit > 1000
ORDER BY 
    max_store_profit DESC;
