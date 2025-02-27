
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        c.customer_id,
        c.total_spent,
        c.order_count,
        c.last_purchase_date,
        COUNT(DISTINCT ws.ws_order_number) FILTER (WHERE ws.ws_web_site_sk IS NOT NULL) AS online_orders
    FROM 
        CustomerStatistics AS c
    JOIN 
        web_sales AS ws ON c.c_customer_id = ws.ws_bill_customer_sk
    WHERE 
        c.total_spent > 1000
    GROUP BY 
        c.customer_id, c.total_spent, c.order_count, c.last_purchase_date
)
SELECT 
    ws.web_site_id,
    ws.total_sales,
    ws.total_orders,
    hs.customer_id,
    hs.total_spent,
    hs.order_count,
    hs.last_purchase_date,
    hs.online_orders
FROM 
    TopWebsites AS ws
JOIN 
    HighSpenders AS hs ON hs.order_count > 5
ORDER BY 
    ws.total_sales DESC, hs.total_spent DESC;
