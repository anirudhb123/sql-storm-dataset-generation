
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
Top_Customers AS (
    SELECT 
        c.customer_id,
        cs.total_web_sales,
        cs.total_orders,
        cs.avg_sales_price,
        cs.max_profit,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_web_sales,
    tc.total_orders,
    tc.avg_sales_price,
    tc.max_profit
FROM 
    Top_Customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_web_sales DESC;

WITH Date_Sales AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year
),
Warehouse_Performance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        warehouse w
    LEFT JOIN 
        catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    dp.d_year,
    SUM(dp.total_sales) AS web_sales_over_time,
    SUM(wp.total_catalog_sales) AS total_catalog_sales,
    SUM(wp.total_store_sales) AS total_store_sales,
    SUM(wp.total_web_sales) AS total_web_sales
FROM 
    Date_Sales dp
JOIN 
    Warehouse_Performance wp ON dp.d_year = YEAR(CURDATE())
GROUP BY 
    dp.d_year
ORDER BY 
    dp.d_year ASC;
