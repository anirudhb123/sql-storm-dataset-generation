
WITH RECURSIVE customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_count
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_spent > (SELECT AVG(total) FROM (SELECT SUM(ss_net_profit) AS total FROM store_sales GROUP BY ss_customer_sk) AS avg_totals)
),
ranked_customers AS (
    SELECT 
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.total_spent,
        cm.purchase_count,
        DENSE_RANK() OVER (ORDER BY cm.total_spent DESC) AS rank
    FROM 
        customer_metrics cm
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rc.purchase_count,
    CASE 
        WHEN rc.purchase_count = 0 THEN 'No Purchases'
        WHEN rc.total_spent BETWEEN 100 AND 500 THEN 'Moderate Spender'
        WHEN rc.total_spent > 500 THEN 'High Roller'
        ELSE 'Unknown'
    END AS spending_category,
    COALESCE((SELECT AVG(total_spent) FROM ranked_customers), 0) AS avg_spent_among_top_customers,
    CONCAT('Customer: ', rc.c_first_name, ' ', rc.c_last_name) AS customer_summary
FROM 
    ranked_customers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.rank;
