
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.total_sales,
    cu.order_count,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    SUM(CASE WHEN ds.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopCustomers cu
JOIN 
    customer_demographics cd ON cu.c_customer_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = cu.c_customer_sk)
JOIN 
    household_demographics ds ON cd.cd_demo_sk = ds.hd_demo_sk
WHERE 
    cu.sales_rank <= 10
GROUP BY 
    cu.c_first_name, 
    cu.c_last_name, 
    cu.total_sales, 
    cu.order_count, 
    d.d_year, 
    d.d_month_seq, 
    d.d_week_seq
ORDER BY 
    cu.total_sales DESC;
