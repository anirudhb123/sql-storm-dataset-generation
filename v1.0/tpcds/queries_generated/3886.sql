
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ReturnSummary AS (
    SELECT 
        sr_returning_customer_sk AS customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_net_loss) AS net_loss
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
FinalSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_credit_rating,
        cs.orders_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.net_loss, 0) AS net_loss,
        cs.total_spent - COALESCE(rs.net_loss, 0) AS net_spent_after_returns
    FROM CustomerSummary cs
    LEFT JOIN ReturnSummary rs ON cs.c_customer_sk = rs.customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.orders_count,
    fs.total_returns,
    fs.net_spent_after_returns,
    CASE 
        WHEN fs.net_spent_after_returns > 1000 THEN 'High Value Customer'
        WHEN fs.net_spent_after_returns BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM FinalSummary fs
WHERE fs.orders_count > 0
ORDER BY fs.net_spent_after_returns DESC, fs.orders_count DESC;
