
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(cr_return_amt, 0)) AS total_return_amt
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_web_return_quantity,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(crs.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(crs.total_return_amt, 0) AS total_return_amt,
        COALESCE(wr.total_web_return_quantity, 0) AS total_web_return_quantity,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns crs ON c.c_customer_sk = crs.cr_returning_customer_sk
    LEFT JOIN WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
),
SalesAnalysis AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    cd.c_customer_sk,
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_return_quantity,
    cd.total_return_amt,
    cd.total_web_return_quantity,
    cd.total_web_return_amt,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN COALESCE(sa.total_sales, 0) = 0 THEN 'No Sales' 
        WHEN cd.total_return_amt > 0 AND sa.total_sales > 0 THEN 
            'Active Customer with Returns'
        ELSE 
            'Active Customer'
    END AS customer_status
FROM CustomerDetails cd
LEFT JOIN SalesAnalysis sa ON cd.c_customer_sk = sa.ws_bill_customer_sk
WHERE (cd.total_return_quantity > 0 OR sa.total_sales > 0)
ORDER BY cd.total_return_amt DESC, total_sales DESC
LIMIT 100;
