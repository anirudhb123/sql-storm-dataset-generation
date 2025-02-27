
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_addr_sk,
        1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_addr_sk
),
SalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        da.total_sales,
        da.order_count,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY da.total_sales DESC) AS sales_rank
    FROM customer_address ca
    JOIN SalesAnalysis da ON ca.ca_address_sk = da.ws_bill_customer_sk
    WHERE da.total_sales > 1000
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    tc.ca_city,
    tc.ca_state,
    tc.total_sales,
    tc.order_count,
    COALESCE(tc.sales_rank, 0) AS sales_rank
FROM CustomerHierarchy ch
LEFT JOIN TopCustomers tc ON ch.c_current_addr_sk = tc.ca_address_sk
WHERE ch.level <= 3
ORDER BY tc.total_sales DESC, ch.c_last_name, ch.c_first_name;
