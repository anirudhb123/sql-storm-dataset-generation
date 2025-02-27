
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
RecentOrders AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_purchase_estimate AS VARCHAR)
        END AS purchase_level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ro.total_orders, 0) AS total_orders,
    COALESCE(ro.total_sales, 0) AS total_sales,
    CASE 
        WHEN cz.total_sales = 0 THEN 'No Sales Activity'
        ELSE CAST((COALESCE(cr.total_return_amount, 0) / NULLIF(cz.total_sales, 0)) * 100 AS DECIMAL(5,2))
    END AS return_percentage,
    CASE 
        WHEN cz.total_orders > 10 THEN 'High Value'
        WHEN cz.total_orders BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CustomerDemographics cd
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.returning_customer_sk
LEFT JOIN RecentOrders ro ON cd.c_customer_sk = ro.ws_bill_customer_sk
LEFT JOIN (
    SELECT 
        c_customer_sk,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY c_customer_sk
    HAVING SUM(ws_sales_price) > 1000
) cz ON cd.c_customer_sk = cz.c_customer_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
AND cd.c_customer_sk IS NOT NULL
ORDER BY return_percentage DESC, cd.c_customer_sk;
