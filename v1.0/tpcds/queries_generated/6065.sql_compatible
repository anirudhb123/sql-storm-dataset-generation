
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS total_ship_days
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000 
    GROUP BY c.c_customer_id
),
FilteredCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.total_orders,
        cs.total_ship_days,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerSales AS cs
    JOIN customer_demographics AS cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE cs.total_spent > 1000 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
),
Summary AS (
    SELECT 
        COUNT(*) AS num_customers,
        AVG(total_spent) AS avg_spent,
        AVG(total_orders) AS avg_orders,
        AVG(total_ship_days) AS avg_ship_days
    FROM FilteredCustomers
)
SELECT 
    s.num_customers,
    s.avg_spent,
    s.avg_orders,
    s.avg_ship_days,
    (SELECT COUNT(DISTINCT c.c_customer_id) FROM customer AS c) AS total_customers
FROM Summary AS s;
