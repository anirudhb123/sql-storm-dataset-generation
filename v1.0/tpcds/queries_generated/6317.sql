
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    wa.w_warehouse_name
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
JOIN 
    store s ON s.s_store_sk = (SELECT ss.ss_store_sk FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk ORDER BY ss.ss_sold_date_sk DESC LIMIT 1)
JOIN 
    warehouse wa ON wa.w_warehouse_sk = s.s_store_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
