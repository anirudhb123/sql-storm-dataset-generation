
WITH CustomerSales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
BestCustomers AS (
    SELECT 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    WHERE cs.total_orders > 5
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returned,
        COUNT(wr.wr_order_number) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        bc.c_first_name,
        bc.c_last_name,
        bc.total_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        (bc.total_sales - COALESCE(cr.total_returned, 0)) AS net_sales
    FROM BestCustomers bc
    LEFT JOIN CustomerReturns cr ON bc.c_first_name = (SELECT c_first_name FROM customer WHERE c_customer_sk = cr.wr_returning_customer_sk)
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returned,
    f.net_sales,
    CASE 
        WHEN f.net_sales < 0 THEN 'Negative Sales'
        WHEN f.net_sales >= 0 AND f.net_sales < 1000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM FinalReport f
WHERE f.net_sales IS NOT NULL
ORDER BY f.net_sales DESC
LIMIT 10;
