
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        s.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
                                 AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY c.c_customer_id, s.ss_sold_date_sk
),
filtered_sales AS (
    SELECT 
        rs.c_customer_id,
        rs.ss_sold_date_sk,
        rs.total_quantity,
        rs.num_transactions
    FROM ranked_sales rs
    WHERE rs.profit_rank <= 10 
      AND rs.total_quantity IS NOT NULL
)
SELECT 
    f.c_customer_id,
    f.ss_sold_date_sk,
    f.total_quantity,
    f.num_transactions,
    COALESCE(CAST(STRING_AGG(CONCAT(CAST(f.total_quantity AS CHAR), ' units sold on ', CAST(f.ss_sold_date_sk AS CHAR)), '; ') 
             ORDER BY f.ss_sold_date_sk) AS CHAR), 'No sales recorded') AS sales_summary,
    (CASE 
        WHEN COUNT(DISTINCT f.c_customer_id) < 5 THEN 'Fewer than 5 customers'
        ELSE 'More than 5 customers'
     END) AS customer_count_status
FROM filtered_sales f
LEFT JOIN customer_demographics cd ON f.c_customer_id = cd.cd_demo_sk
GROUP BY f.c_customer_id, f.ss_sold_date_sk, f.total_quantity, f.num_transactions
HAVING SUM(f.total_quantity) IS NULL OR AVG(f.total_quantity) > 0
ORDER BY f.total_quantity DESC NULLS LAST
LIMIT 50;
