
WITH RECURSIVE customer_tree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS depth
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT sr_returning_customer_sk FROM store_returns WHERE sr_return_quantity > 1)
    
    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ct.depth + 1
    FROM customer c
    JOIN customer_tree ct ON c.c_current_cdemo_sk = ct.c_current_cdemo_sk
    WHERE c.c_customer_sk <> ct.c_customer_sk
), customer_info AS (
    SELECT ct.c_customer_sk, ct.c_first_name, ct.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT ct.depth) AS levels_of_loyalty,
           SUM(CASE WHEN cd.cd_purchase_estimate IS NULL THEN 0 ELSE cd.cd_purchase_estimate END) AS total_est_purchase
    FROM customer_tree ct
    LEFT JOIN customer_demographics cd ON ct.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ct.c_customer_sk, ct.c_first_name, ct.c_last_name, cd.cd_gender, cd.cd_marital_status
), recent_sales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY ws_bill_customer_sk
), cumulative_sales AS (
    SELECT r.ws_bill_customer_sk, r.total_net_profit,
           RANK() OVER (ORDER BY r.total_net_profit DESC) AS rank_sales
    FROM recent_sales r
), customer_ranked AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender,
           COALESCE(cs.total_net_profit, 0) AS total_net_profit,
           ci.levels_of_loyalty,
           CASE WHEN ci.cd_gender = 'M' THEN 'Male'
                WHEN ci.cd_gender = 'F' THEN 'Female'
                ELSE 'Other' END AS gender_description
    FROM customer_info ci
    LEFT JOIN cumulative_sales cs ON ci.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT cr.c_customer_sk, cr.c_first_name, cr.c_last_name, cr.gender_description,
       cr.total_net_profit, cr.levels_of_loyalty,
       CASE WHEN cr.total_net_profit IS NULL THEN 'No Sales'
            WHEN cr.levels_of_loyalty > 2 THEN 'Loyal'
            ELSE 'Casual' END AS customer_type,
       (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NULL) AS null_cd_count
FROM customer_ranked cr
WHERE cr.levels_of_loyalty >= 1
ORDER BY cr.total_net_profit DESC NULLS LAST
LIMIT 50;

