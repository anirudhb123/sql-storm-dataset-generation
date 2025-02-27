
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        C.c_preferred_cust_flag,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer C ON ws.ws_bill_customer_sk = C.c_customer_sk
    WHERE 
        C.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
SalesSummary AS (
    SELECT 
        web_site_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
    GROUP BY 
        web_site_sk
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_sales, 0) AS total_sales
FROM 
    warehouse w
LEFT JOIN 
    SalesSummary ss ON w.warehouse_sk = ss.web_site_sk
WHERE 
    w.warehouse_gmt_offset BETWEEN -8.00 AND -5.00
ORDER BY 
    total_sales DESC;
