
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_ext_sales_price) AS avg_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ss.total_sales,
        ss.order_count,
        ss.avg_sales
    FROM CustomerHierarchy ch
    LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ss.total_sales IS NOT NULL
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    COALESCE(tc.avg_sales, 0.00) AS avg_sales,
    (SELECT COUNT(DISTINCT wr_item_sk) FROM web_returns wr WHERE wr_returning_customer_sk = tc.c_customer_sk) AS return_count,
    (SELECT STRING_AGG(DISTINCT CONCAT(p.p_promo_name, ': ', p.p_discount_active) SEPARATOR ', ') 
     FROM promotion p 
     JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS promotions_used
FROM TopCustomers tc
ORDER BY total_sales DESC
LIMIT 10;
