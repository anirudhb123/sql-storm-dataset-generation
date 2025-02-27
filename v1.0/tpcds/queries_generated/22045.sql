
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS return_order_count,
        SUM(cr_return_amt) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Demographics AS (
    SELECT
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        rd.return_order_count,
        rd.total_returned_quantity,
        sd.total_sold_quantity,
        sd.total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN CustomerReturns rd ON c.c_customer_sk = rd.cr_returning_customer_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(d.cd_gender, 'Unknown') AS gender,
    COALESCE(d.cd_marital_status, 'Unknown') AS marital_status,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    d.cd_dep_count,
    d.cd_dep_employed_count,
    d.return_order_count,
    d.total_returned_quantity,
    d.total_sold_quantity,
    d.total_net_profit,
    (CASE 
        WHEN d.return_order_count IS NULL THEN 'No Returns'
        WHEN d.total_returned_quantity > 0 AND d.total_sold_quantity > 0 THEN 'Frequent Returner'
        WHEN d.total_sold_quantity IS NULL THEN 'No Sales Activity'
        ELSE 'Regular Customer'
    END) AS customer_category,
    (SELECT COUNT(*) FROM customer WHERE c_birth_month = d.cd_purchase_estimate % 12) AS similar_birth_month_count
FROM customer c
INNER JOIN Demographics d ON c.c_customer_sk = d.c_customer_sk
WHERE (d.return_order_count IS NOT NULL OR d.total_sold_quantity IS NOT NULL)
ORDER BY d.total_net_profit DESC, d.cd_purchase_estimate ASC
LIMIT 100;
