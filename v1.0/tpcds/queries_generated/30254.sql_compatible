
WITH RECURSIVE sales_cte AS (
    SELECT ws.web_site_sk, SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023)
    GROUP BY ws.web_site_sk
    UNION ALL
    SELECT wc.web_site_sk, SUM(wc.ws_net_profit) 
    FROM web_sales wc
    INNER JOIN sales_cte sc ON wc.web_site_sk = sc.web_site_sk
    WHERE wc.ws_sold_date_sk < (SELECT MAX(d.d_date_sk) 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023)
    GROUP BY wc.web_site_sk
),
average_sales AS (
    SELECT web_site_sk, AVG(total_net_profit) AS avg_profit
    FROM sales_cte
    GROUP BY web_site_sk
),
high_performers AS (
    SELECT cs.c_customer_id, cs.c_first_name, cs.c_last_name, 
           a.avg_profit, cd.cd_gender
    FROM customer cs
    JOIN customer_demographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN average_sales a ON cs.c_customer_sk = a.web_site_sk
    WHERE a.avg_profit > 1000
),
top_stores AS (
    SELECT s.s_store_id, s.s_store_name, 
           SUM(ss.ss_net_profit) AS store_profit
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id, s.s_store_name
    HAVING SUM(ss.ss_net_profit) > 5000
),
return_data AS (
    SELECT sr.sr_returned_date_sk, COUNT(sr.sr_ticket_number) AS return_count,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IS NOT NULL
    GROUP BY sr.sr_returned_date_sk
)
SELECT h.c_customer_id, h.c_first_name, h.c_last_name,
       t.s_store_id, t.s_store_name,
       r.return_count, r.total_return_amount,
       CASE 
           WHEN r.total_return_amount IS NULL THEN 'No Returns'
           ELSE 'Returns Processed'
       END AS return_status
FROM high_performers h
JOIN top_stores t ON t.store_profit > (SELECT AVG(store_profit) FROM top_stores)
LEFT JOIN return_data r ON r.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
WHERE h.cd_gender = 'F'
ORDER BY h.c_last_name, h.c_first_name;
