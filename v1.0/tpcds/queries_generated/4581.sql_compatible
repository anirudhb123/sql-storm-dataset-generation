
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        NTILE(4) OVER (ORDER BY cs.total_sales DESC) AS sales_quartile
    FROM CustomerSales cs
    WHERE cs.total_sales > 1000
),
ProductReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hvc.sales_quartile,
    COALESCE(pr.total_returned, 0) AS total_returned,
    COALESCE(pr.total_return_amt, 0) AS total_return_amt
FROM HighValueCustomers hvc
LEFT JOIN ProductReturns pr ON hvc.c_customer_sk = pr.sr_customer_sk
JOIN customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
WHERE hvc.sales_quartile = 1
  AND ca.ca_state IS NOT NULL
ORDER BY hvc.total_sales DESC;
