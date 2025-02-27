
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_return_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
StoreSalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_web_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    coalesce(cr.total_web_returns, 0) AS total_web_returns,
    coalesce(cr.total_return_amount, 0) AS total_return_amount,
    coalesce(ss.total_sales, 0) AS total_store_sales,
    coalesce(ws.total_web_sales, 0) AS total_web_sales,
    CASE 
        WHEN coalesce(ss.total_sales, 0) + coalesce(ws.total_web_sales, 0) > 1000 THEN 'High Value'
        WHEN coalesce(ss.total_sales, 0) + coalesce(ws.total_web_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN StoreSalesData ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN WebSalesData ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE cd.cd_marital_status = 'M'
    AND cd.cd_gender = 'F'
ORDER BY customer_value DESC, total_web_returns DESC;
