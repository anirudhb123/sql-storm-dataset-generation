
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_coupon_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_quantity DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_spent,
        COALESCE(tc.total_return_amt, 0) AS total_returns,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ws_ext_sales_price), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns tc ON c.c_customer_sk = tc.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, tc.total_return_amt
    HAVING 
        SUM(ws_ext_sales_price) IS NOT NULL OR total_returns > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_returns,
    (tc.total_spent - tc.total_returns) AS net_spent,
    CASE 
        WHEN (tc.total_spent - tc.total_returns) > 1000 THEN 'High Value'
        WHEN (tc.total_spent - tc.total_returns) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    net_spent DESC;

