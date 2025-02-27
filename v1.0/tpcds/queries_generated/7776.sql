
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSummary cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    d.d_date AS last_purchase_date,
    w.w_warehouse_name
FROM TopCustomers tc
JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE tc.sales_rank <= 10 -- Getting top 10 customers
AND d.d_date >= DATEADD(YEAR, -1, CURRENT_DATE)
ORDER BY tc.total_sales DESC;
