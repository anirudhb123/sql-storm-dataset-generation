
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_ext_sales_price
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(ts.ws_order_number) AS total_orders,
        SUM(ts.ws_ext_sales_price) AS total_sales,
        AVG(ts.ws_ext_sales_price) AS avg_sales
    FROM 
        TopSales ts
    JOIN 
        warehouse w ON ts.web_site_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.w_warehouse_id,
    ss.total_orders,
    ss.total_sales,
    ss.avg_sales,
    COALESCE((
        SELECT COUNT(*) 
        FROM customer_address ca 
        WHERE ca.ca_city IS NOT NULL 
          AND ca.ca_state = 'CA' 
          AND ca.ca_country = 'USA'
    ), 0) AS ca_address_count,
    COALESCE((
        SELECT COUNT(DISTINCT c.c_customer_sk)
        FROM customer c
        WHERE c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE) 
          AND c.c_birth_day IS NOT NULL
    ), 0) AS birthday_customers_count
FROM 
    SalesSummary ss
ORDER BY 
    ss.total_sales DESC;
