
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        web_site ws_ws ON ws.ws_web_site_sk = ws_ws.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 365 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws_ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        rank_sales <= 10
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    ts.total_sales,
    ts.total_orders,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales
FROM 
    TopSites ts
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_web_site_sk = ts.web_site_id)
LEFT JOIN 
    catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = 'New York'))
GROUP BY 
    ts.web_site_id, ts.total_quantity, ts.total_sales, ts.total_orders, d.d_year, d.d_month_seq
ORDER BY 
    ts.total_sales DESC;
