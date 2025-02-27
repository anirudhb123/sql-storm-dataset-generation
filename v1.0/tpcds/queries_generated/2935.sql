
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(NULLIF(cd.cd_dep_count, 0), 1) AS dep_count,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
income_distribution AS (
    SELECT 
        h.hd_demo_sk, 
        h.hd_income_band_sk,
        COUNT(h.hd_demo_sk) AS num_customers,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY h.hd_demo_sk, h.hd_income_band_sk
),
ranked_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_orders,
        cs.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_profit DESC) AS rank_by_gender,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS overall_rank
    FROM customer_summary cs
)
SELECT 
    r.c_customer_id,
    r.total_orders,
    r.total_profit,
    CASE 
        WHEN r.rank_by_gender <= 10 THEN 'Top 10 by Gender'
        WHEN r.overall_rank <= 10 THEN 'Top 10 Overall'
        ELSE 'Other'
    END AS customer_rank_category,
    id.num_customers,
    id.married_count,
    id.female_count
FROM ranked_customers r
JOIN income_distribution id ON r.c_customer_id = id.hd_demo_sk
WHERE r.total_profit >= (
    SELECT AVG(total_profit) FROM ranked_customers
)
ORDER BY r.total_profit DESC, r.total_orders ASC
LIMIT 100;
