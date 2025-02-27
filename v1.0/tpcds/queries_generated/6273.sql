
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_id
), TotalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_sales,
        ss.total_store_sales,
        ss.total_store_orders
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreSales ss ON cs.total_orders > 0 AND ss.total_store_orders > 0
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cs.c_customer_id) AS num_customers,
    SUM(cs.total_sales) AS total_web_sales,
    SUM(coalesce(ss.total_store_sales, 0)) AS total_store_sales,
    (SUM(cs.total_sales) + SUM(coalesce(ss.total_store_sales, 0))) AS grand_total_sales
FROM 
    TotalSales cs
LEFT JOIN 
    customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    num_customers DESC, grand_total_sales DESC;
