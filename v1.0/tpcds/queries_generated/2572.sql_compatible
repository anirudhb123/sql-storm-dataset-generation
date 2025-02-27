
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM
        CustomerSales cs 
    WHERE
        cs.sales_rank <= 10
),
Returns AS (
    SELECT
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_return_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM
        web_returns wr
    GROUP BY
        wr.wr_returning_customer_sk
),
CustomerStats AS (
    SELECT
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        (tc.total_sales - COALESCE(r.total_return_amt, 0)) AS net_sales
    FROM
        TopCustomers tc
    LEFT JOIN
        Returns r ON tc.c_customer_sk = r.wr_returning_customer_sk
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    cs.return_count,
    cs.total_return_amt,
    cs.net_sales,
    TRIM(CONCAT(cs.c_first_name, ' ', cs.c_last_name)) AS full_name,
    CASE
        WHEN cs.net_sales > 1000 THEN 'High Value Customer'
        WHEN cs.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM
    CustomerStats cs
ORDER BY
    cs.total_sales DESC;
