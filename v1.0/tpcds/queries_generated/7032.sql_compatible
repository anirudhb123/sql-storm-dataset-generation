
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    d.d_year,
    w.w_warehouse_name
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_id)
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_id LIMIT 1)
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
