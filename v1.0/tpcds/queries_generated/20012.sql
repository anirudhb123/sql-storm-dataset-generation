
WITH AddressStats AS (
    SELECT ca_county, COUNT(*) AS customer_count,
           SUM(CASE WHEN ca_state IS NULL THEN 1 ELSE 0 END) AS null_states,
           AVG(ca_gmt_offset) AS avg_gmt
    FROM customer_address
    GROUP BY ca_county
),
CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_amt_inc_tax) AS total_return
    FROM store_returns
    GROUP BY sr_customer_sk
),
Promotions AS (
    SELECT p_promo_id, COUNT(*) AS promo_count
    FROM promotion
    WHERE p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = '1') 
      AND p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_current_year = '1')
    GROUP BY p_promo_id
),
TopReturns AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_amt) AS total_return,
           ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amt) DESC) AS rn
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CombinedStats AS (
    SELECT coalesce(a.ca_county, 'Unknown') AS county,
           a.customer_count,
           a.null_states,
           a.avg_gmt,
           COALESCE(c.total_return, 0) AS customer_total_return,
           COALESCE(p.promo_count, 0) AS promo_count
    FROM AddressStats AS a
    LEFT JOIN CustomerReturns AS c ON a.customer_count = c.sr_customer_sk
    LEFT JOIN Promotions AS p ON a.customer_count = p.promo_count
),
FinalStats AS (
    SELECT county, customer_count, null_states, avg_gmt, customer_total_return, promo_count,
           CASE 
               WHEN customer_total_return > 1000 THEN 'High Return'
               WHEN customer_total_return BETWEEN 500 AND 1000 THEN 'Medium Return'
               ELSE 'Low Return'
           END AS return_category,
           ROW_NUMBER() OVER (PARTITION BY return_category ORDER BY customer_count DESC) AS return_rank
    FROM CombinedStats
)
SELECT county, customer_count, null_states, avg_gmt, customer_total_return, promo_count,
       return_category
FROM FinalStats
WHERE return_rank <= 5
ORDER BY return_category, customer_count DESC
UNION
SELECT 'Overall' AS county,
       COUNT(*) AS total_customers,
       SUM(null_states) AS total_null_states,
       AVG(avg_gmt) AS overall_avg_gmt,
       SUM(customer_total_return) AS overall_total_return,
       SUM(promo_count) AS overall_promo_count,
       'Summary' AS return_category
FROM FinalStats
GROUP BY return_category;
