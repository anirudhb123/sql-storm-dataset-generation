
WITH customer_stats AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c_customer_sk) AS total_customers, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
        AVG(cd_dep_count) AS avg_dependents
    FROM customer
    JOIN customer_demographics ON c_customer_sk = cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk, 
        SUM(ws_net_paid) AS total_sales, 
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
returns_summary AS (
    SELECT 
        wr_returning_cdemo_sk, 
        SUM(wr_return_amt_inc_tax) AS total_returned, 
        COUNT(wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_cdemo_sk
),
final_summary AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_customers,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_profit, 0) - COALESCE(rs.total_returned, 0)) / NULLIF(cs.total_customers, 0) AS avg_profit_per_customer
    FROM customer_stats cs
    LEFT JOIN sales_summary ss ON cs.cd_marital_status = ss.ws_bill_cdemo_sk
    LEFT JOIN returns_summary rs ON cs.cd_marital_status = rs.wr_returning_cdemo_sk
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    total_customers, 
    total_sales, 
    total_profit, 
    total_returned, 
    total_returns, 
    avg_profit_per_customer
FROM final_summary
ORDER BY total_profit DESC, total_sales DESC;
