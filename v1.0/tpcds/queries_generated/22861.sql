
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
    UNION ALL
    SELECT 
        cs.cs_call_center_sk AS web_site_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        RANK() OVER (PARTITION BY cs.cs_call_center_sk ORDER BY cs.cs_sales_price DESC) AS rank_sales
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_dow IN (1, 2, 3, 4, 5))
    ORDER BY 
        web_site_sk, rank_sales
),
SalesSummary AS (
    SELECT 
        web_site_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        RankedSales
    WHERE 
        rank_sales <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    ws.web_site_id,
    ss.total_orders,
    ss.total_revenue,
    COALESCE(ss.total_revenue / NULLIF(ss.total_orders, 0), 0) AS avg_revenue_per_order,
    (SELECT COUNT(*) FROM customer_address ca 
     WHERE ca.ca_state = 'CA' AND 
           (SELECT COUNT(*) FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk) > 100) AS high_density_customers
FROM 
    web_site ws
LEFT JOIN 
    SalesSummary ss ON ws.web_site_sk = ss.web_site_sk
WHERE 
    ws.web_class = 'Retail' AND 
    ss.total_revenue > (SELECT AVG(total_revenue) FROM SalesSummary)
ORDER BY 
    avg_revenue_per_order DESC, 
    total_orders DESC
LIMIT 50;
