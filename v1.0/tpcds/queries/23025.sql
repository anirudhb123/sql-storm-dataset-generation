WITH RecursiveCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_sales
    FROM RecursiveCustomerSales rc
    WHERE rc.sales_rank <= 10
    AND rc.total_sales > (SELECT AVG(total_sales) FROM RecursiveCustomerSales)
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    COALESCE(cd.cd_gender, 'U') AS gender,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = f.c_customer_sk) AS store_purchases,
    (SELECT SUM(sr_return_quantity) FROM store_returns sr WHERE sr.sr_customer_sk = f.c_customer_sk) AS total_returns,
    CASE 
        WHEN f.total_sales IS NULL THEN 'No Sales'
        WHEN f.total_sales < 1000 THEN 'Low Spender'
        WHEN f.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Roller'
    END AS spending_category
FROM FilteredCustomers f
LEFT JOIN customer_demographics cd ON f.c_customer_sk = cd.cd_demo_sk
WHERE f.c_customer_sk IN (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_month = EXTRACT(MONTH FROM cast('2002-10-01' as date)) 
    AND c.c_birth_day = EXTRACT(DAY FROM cast('2002-10-01' as date))
)
ORDER BY f.total_sales DESC
OFFSET (SELECT count(*) / 2 FROM FilteredCustomers) ROWS
FETCH NEXT 5 ROWS ONLY;