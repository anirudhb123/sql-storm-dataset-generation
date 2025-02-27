
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
    HAVING 
        SUM(ws_ext_sales_price) > 1000
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        unique_customers
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.web_site_id,
    t.total_sales,
    t.total_orders,
    t.unique_customers,
    AVG(cd_dep_count) AS avg_dependent_count,
    COUNT(DISTINCT ca.ca_address_sk) AS total_addresses
FROM 
    TopWebSites t
JOIN 
    web_site ws ON t.web_site_id = ws.web_site_id
JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws.web_site_sk = web_sales.ws_web_site_sk
    )
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    t.web_site_id, t.total_sales, t.total_orders, t.unique_customers
ORDER BY 
    t.total_sales DESC;
