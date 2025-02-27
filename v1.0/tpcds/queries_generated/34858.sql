
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_month_seq, d_year, 1 AS level
    FROM date_dim
    WHERE d_date = CURRENT_DATE
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_month_seq, d.d_year, level + 1
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk + 1
    WHERE level < 12
), 
CustomerPurchases AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateHierarchy)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerPurchases c
)
SELECT tc.rank, 
       tc.c_first_name || ' ' || tc.c_last_name AS full_name, 
       cp.total_spent,
       (SELECT COUNT(*) FROM store s 
        WHERE s.s_number_employees > 50) AS s_large_stores,
       COALESCE((SELECT COUNT(*) FROM store_sales ss 
                  WHERE ss.ss_customer_sk = tc.c_customer_sk 
                  AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM DateHierarchy)), 0) AS store_purchases
FROM TopCustomers tc
JOIN CustomerPurchases cp ON tc.c_customer_sk = cp.c_customer_sk
WHERE tc.rank <= 10;
