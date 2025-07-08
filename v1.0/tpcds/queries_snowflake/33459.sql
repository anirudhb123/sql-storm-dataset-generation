
WITH sale_dates AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_date <= '2022-12-31'
    UNION ALL
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_date > (SELECT MAX(d_date) FROM sale_dates)
)
SELECT
    c.c_customer_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    MAX(ss.ss_net_paid) AS max_net_paid,
    MIN(ss.ss_net_paid) AS min_net_paid,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
FROM customer AS c
LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN item AS i ON ss.ss_item_sk = i.i_item_sk
JOIN sale_dates AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year >= 2020 AND 
    (c.c_birth_year IS NULL OR (c.c_birth_year < 1980 AND c.c_birth_month >= 6))
GROUP BY 
    c.c_customer_id
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC;
