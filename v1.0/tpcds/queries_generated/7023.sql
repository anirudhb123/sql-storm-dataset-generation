
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.customer_sk, c.first_name, c.last_name, cs.total_sales,
           RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT tc.first_name, tc.last_name, tc.total_sales, 
       da.d_date AS sale_date
FROM TopCustomers tc
JOIN date_dim da ON da.d_date_sk = CURRENT_DATE
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
