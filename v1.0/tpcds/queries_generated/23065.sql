
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws.net_profit, 
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS sales_rank,
        SUM(ws.net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_net_profit
    FROM web_sales ws
    WHERE ws.net_profit IS NOT NULL
), 
high_ranked_sales AS (
    SELECT * 
    FROM ranked_sales 
    WHERE sales_rank = 1
), 
return_data AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.return_amt) AS total_returned_amount,
        COUNT(wr.return_quantity) AS total_returns
    FROM web_returns wr
    GROUP BY wr.refunded_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Unknown' 
            ELSE cd.cd_gender 
        END AS gender, 
        cd.cd_marital_status,
        COALESCE(ihb.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(ihb.ib_upper_bound, 500000) AS income_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ihb ON hd.hd_income_band_sk = ihb.ib_income_band_sk
), 
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.gender,
        ci.cd_marital_status,
        r.total_returned_amount,
        r.total_returns,
        hs.total_net_profit
    FROM customer_info ci
    LEFT JOIN return_data r ON ci.c_customer_sk = r.refunded_customer_sk
    JOIN high_ranked_sales hs ON hs.web_site_sk = ci.c_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.gender,
    fr.cd_marital_status,
    COALESCE(fr.total_returned_amount, 0) AS returned_amount,
    COALESCE(fr.total_returns, 0) AS returns_count,
    CASE 
        WHEN fr.total_net_profit >= 10000 THEN 'High' 
        WHEN fr.total_net_profit BETWEEN 5000 AND 9999 THEN 'Medium' 
        ELSE 'Low' 
    END AS profitability_category
FROM final_report fr
WHERE fr.total_returns IS NULL OR fr.total_returned_amount > 500
ORDER BY fr.c_customer_sk;
