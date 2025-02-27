
WITH RECURSIVE SalesCTE AS (
    SELECT s_store_sk, 
           SUM(ss_net_profit) AS total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM store_sales 
    GROUP BY s_store_sk
    HAVING SUM(ss_net_profit) > 0
),
RankedStores AS (
    SELECT sla.s_store_sk,
           s.s_store_name,
           sla.total_net_profit,
           DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS store_ranking
    FROM SalesCTE sla
    JOIN store s ON sla.s_store_sk = s.s_store_sk
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COALESCE(wr_return_amount, 0) AS web_return_amount,
       COALESCE(sr_return_amt, 0) AS store_return_amount,
       r.store_ranking,
       CASE 
           WHEN wr_return_amount > 100 THEN 'High'
           WHEN wr_return_amount > 0 THEN 'Medium'
           ELSE 'None'
       END AS return_category
FROM customer c
LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN RankedStores r ON r.s_store_sk = sr.s_store_sk OR r.s_store_sk = wr.wr_returning_addr_sk
WHERE c.c_birth_year BETWEEN 1980 AND 1990
  AND (wr_return_amount IS NOT NULL OR sr_return_amt IS NOT NULL)
ORDER BY r.store_ranking, c.c_last_name, c.c_first_name;
