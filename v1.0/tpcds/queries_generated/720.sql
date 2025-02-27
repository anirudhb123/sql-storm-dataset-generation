
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        customer_sk, total_profit, order_count
    FROM SalesData
    WHERE rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        tc.total_profit,
        tc.order_count
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN TopCustomers AS tc ON c.c_customer_sk = tc.customer_sk
),
CombinedReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_net_loss) AS total_loss
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    UNION ALL
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_net_loss) AS total_loss
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerReturns AS (
    SELECT 
        cr.customer_sk,
        COALESCE(SUM(cr.total_loss), 0) AS total_return_loss
    FROM (
        SELECT customer_sk, total_loss FROM CombinedReturns
    ) cr
    GROUP BY cr.customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_city,
    cd.ca_state,
    cd.total_profit,
    cd.order_count,
    cr.total_return_loss,
    (cd.total_profit - cr.total_return_loss) AS net_profit_after_returns
FROM CustomerDetails cd
LEFT JOIN CustomerReturns cr ON cd.customer_sk = cr.customer_sk
WHERE cd.total_profit > 0
ORDER BY net_profit_after_returns DESC
LIMIT 50;
