
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_id, d.d_year
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_order_number END) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > 1000
),
WarehouseSales AS (
    SELECT 
        ws.ws_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_warehouse_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_warehouse_sk
)
SELECT 
    r.web_site_id,
    r.d_year,
    r.total_sales,
    w.total_warehouse_sales,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count
FROM 
    RankedSales r
JOIN 
    WarehouseSales w ON r.web_site_id = w.ws_warehouse_sk 
LEFT JOIN 
    HighValueCustomers hvc ON r.web_site_id = hvc.c_customer_sk
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.web_site_id, r.d_year, r.total_sales, w.total_warehouse_sales
ORDER BY 
    r.d_year, r.total_sales DESC;
