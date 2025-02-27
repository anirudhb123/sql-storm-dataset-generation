
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound,
           CASE 
               WHEN ib_lower_bound IS NULL THEN 'Unknown'
               WHEN ib_upper_bound IS NULL THEN 'Infinite'
               ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
           END AS income_range
    FROM income_band
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound,
           CASE 
               WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
               WHEN ib.ib_upper_bound IS NULL THEN 'Infinite'
               ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
           END AS income_range
    FROM income_band ib
    JOIN income_brackets ib2 ON ib.ib_income_band_sk = ib2.ib_income_band_sk
    WHERE ib.ib_lower_bound > 0
),
customer_income AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk,
           COALESCE(NULLIF(cd.cd_credit_rating, 'Poor'), 'Unknown') AS credit_rating,
           COUNT(DISTINCT o.cs_order_number) AS total_orders,
           AVG(o.cs_net_profit) AS avg_profit
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN catalog_sales o ON c.c_customer_sk = o.cs_bill_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, hd.hd_income_band_sk, cd.cd_credit_rating
),
order_summary AS (
    SELECT ci.c_customer_sk, 
           SUM(CASE WHEN o.cs_net_profit < 0 THEN -o.cs_net_profit ELSE 0 END) AS total_loss,
           COUNT(CASE WHEN o.cs_net_profit > 0 THEN o.cs_order_number END) AS positive_orders,
           RANK() OVER (PARTITION BY ci.income_band_sk ORDER BY SUM(o.cs_net_profit) DESC) AS rank_orders
    FROM customer_income ci
    LEFT JOIN catalog_sales o ON ci.c_customer_sk = o.cs_bill_customer_sk
    GROUP BY ci.c_customer_sk, ci.income_band_sk
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ib.income_range,
        ci.credit_rating,
        COALESCE(oss.total_loss, 0) AS total_loss,
        COALESCE(oss.positive_orders, 0) AS positive_orders,
        oss.rank_orders
    FROM customer_income ci
    LEFT JOIN income_brackets ib ON ci.income_band_sk = ib.ib_income_band_sk
    LEFT JOIN order_summary oss ON ci.c_customer_sk = oss.c_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN rank_orders IS NULL THEN 'Unranked'
        ELSE CAST(rank_orders AS VARCHAR)
    END AS final_rank
FROM final_report
WHERE (credit_rating IS NOT NULL AND credit_rating <> 'Unknown') 
      OR (total_loss > 0 AND positive_orders > 0)
ORDER BY total_loss DESC, positive_orders DESC
LIMIT 100;
