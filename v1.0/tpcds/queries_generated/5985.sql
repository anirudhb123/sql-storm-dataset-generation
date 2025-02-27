
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE YEAR(ws.ws_sold_date_sk) = 2023
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.cd_gender, 
        cs.cd_marital_status, 
        cs.cd_education_status,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM CustomerStats cs
    WHERE cs.total_sales > 1000
),
SalesSummary AS (
    SELECT 
        COUNT(*) AS high_value_customer_count,
        AVG(total_sales) AS avg_sales,
        SUM(order_count) AS total_orders
    FROM HighValueCustomers
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.total_sales,
    hvc.order_count,
    ss.high_value_customer_count,
    ss.avg_sales,
    ss.total_orders
FROM HighValueCustomers hvc
CROSS JOIN SalesSummary ss
WHERE hvc.rank <= 10
ORDER BY hvc.total_sales DESC;
