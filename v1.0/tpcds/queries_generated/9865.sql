
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.customer_sk,
           ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM CustomerSales cs
)
SELECT c.c_first_name,
       c.c_last_name,
       cs.total_sales,
       cs.order_count,
       COALESCE(cd.cd_gender, 'Unknown') AS gender,
       COALESCE(hd.hd_income_band_sk, -1) AS income_band
FROM TopCustomers tc
JOIN CustomerSales cs ON tc.customer_sk = cs.c_customer_sk
LEFT JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
WHERE tc.rank <= 10
ORDER BY cs.total_sales DESC;
