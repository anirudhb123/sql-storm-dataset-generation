
WITH RECURSIVE customer_income AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN hd_income_band_sk IS NOT NULL THEN ib_upper_bound
            ELSE 0
        END AS income
    FROM 
        customer_demographics
    LEFT JOIN 
        household_demographics ON customer_demographics.cd_demo_sk = household_demographics.hd_demo_sk
    LEFT JOIN 
        income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
combined_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        i.income
    FROM 
        customer c
    LEFT JOIN 
        sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN 
        returns_summary r ON c.c_customer_sk = r.wr_returning_customer_sk
    LEFT JOIN 
        customer_income i ON c.c_current_cdemo_sk = i.cd_demo_sk
),
final_summary AS (
    SELECT 
        income,
        AVG(total_net_profit) AS avg_net_profit,
        MAX(total_net_profit) AS max_net_profit,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        CASE 
            WHEN COUNT(DISTINCT c_customer_sk) = 0 THEN NULL 
            ELSE SUM(CASE WHEN total_return_loss > avg_net_profit THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT c_customer_sk)
        END AS return_rate_above_avg
    FROM 
        combined_stats
    GROUP BY 
        income
)

SELECT 
    income,
    avg_net_profit,
    max_net_profit,
    customer_count,
    COALESCE(return_rate_above_avg, 0) AS return_rate_above_avg
FROM 
    final_summary
ORDER BY 
    income DESC
UNION ALL
SELECT 
    'Total' AS income,
    SUM(avg_net_profit),
    SUM(max_net_profit),
    SUM(customer_count),
    SUM(return_rate_above_avg) / COUNT(*)
FROM 
    final_summary
WHERE 
    income IS NOT NULL
HAVING 
    COUNT(DISTINCT income) > 0;
