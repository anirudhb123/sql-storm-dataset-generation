
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990 
        AND c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY
        c.c_customer_sk
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM
        CustomerSales cs
    WHERE
        cs.total_orders > 5
),
StoreReturns AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(sr.cr_item_sk) AS total_returns,
        SUM(sr.cr_return_amt) AS total_returned_amt
    FROM
        catalog_returns sr
    GROUP BY
        sr.returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_profit,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.total_returned_amt, 0) AS total_returned_amt,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High Value'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    TopCustomers tc
LEFT JOIN 
    StoreReturns sr ON tc.c_customer_sk = sr.returning_customer_sk
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    NULL AS total_orders,
    NULL AS total_profit,
    COUNT(sr.returning_customer_sk) AS total_returns,
    SUM(sr.cr_return_amt) AS total_returned_amt,
    'Total Returns' AS customer_value_category
FROM 
    StoreReturns sr
WHERE 
    sr.total_returns > 0;
