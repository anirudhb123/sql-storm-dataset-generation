
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
SalesSummary AS (
    SELECT 
        web_site_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        RankedSales
    WHERE 
        sale_rank <= 10
    GROUP BY 
        web_site_sk
),
TopWebSites AS (
    SELECT 
        w.web_site_id,
        ws.total_orders,
        ws.total_revenue,
        RANK() OVER (ORDER BY ws.total_revenue DESC) AS revenue_rank
    FROM 
        web_site w
    LEFT JOIN 
        SalesSummary ws ON w.web_site_sk = ws.web_site_sk
)
SELECT 
    t.web_site_id,
    COALESCE(t.total_orders, 0) AS total_orders,
    COALESCE(t.total_revenue, 0.00) AS total_revenue,
    CASE 
        WHEN t.revenue_rank <= 5 THEN 'Top 5'
        WHEN t.revenue_rank IS NULL THEN 'No Sales'
        ELSE 'Other'
    END AS category
FROM 
    TopWebSites t
ORDER BY 
    t.revenue_rank;
