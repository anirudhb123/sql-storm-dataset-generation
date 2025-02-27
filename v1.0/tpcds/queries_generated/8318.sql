
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY DATE(d.d_date)) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_id, DATE(d.d_date)
),
TopSales AS (
    SELECT 
        web_site_id,
        sale_date,
        total_quantity,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ts.total_sales) AS customer_total_sales,
        COUNT(DISTINCT ts.order_count) AS total_orders
    FROM 
        TopSales ts
    JOIN 
        web_sales ws ON ts.web_site_id = ws.ws_web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cs.c_customer_id,
    cs.customer_total_sales,
    cs.total_orders,
    RANK() OVER (ORDER BY cs.customer_total_sales DESC) AS sales_rank
FROM 
    CustomerSales cs
WHERE 
    cs.customer_total_sales > (SELECT AVG(customer_total_sales) FROM CustomerSales)
ORDER BY 
    cs.customer_total_sales DESC;
