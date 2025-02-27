WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451550 
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.avg_order_value, 0) AS avg_order_value,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    tc.total_orders,
    tc.total_sales,
    tc.avg_order_value,
    ch.level AS customer_level,
    CASE 
        WHEN tc.total_sales > 10000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM CustomerHierarchy ch
JOIN TopCustomers tc ON ch.c_customer_sk = tc.c_customer_sk
WHERE tc.sales_rank <= 10
ORDER BY customer_level, tc.total_sales DESC;