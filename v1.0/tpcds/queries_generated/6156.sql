
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
FinalResults AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.cd_gender,
        hvc.cd_marital_status,
        hvc.cd_education_status,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM HighValueCustomers hvc
    JOIN CustomerSales cs ON hvc.c_customer_sk = cs.c_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_education_status,
    f.total_sales,
    f.order_count,
    f.avg_order_value,
    f.sales_rank
FROM FinalResults f
WHERE f.sales_rank <= 10
ORDER BY f.total_sales DESC;
