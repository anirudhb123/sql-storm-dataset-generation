
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(ss.ticket_number) AS total_purchases,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_net_paid) AS avg_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_purchases,
        cs.total_net_profit,
        cs.avg_spent
    FROM customer_stats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.avg_spent > (
        SELECT AVG(avg_spent) 
        FROM customer_stats
    )
), 
purchase_dates AS (
    SELECT 
        ss.ss_customer_sk,
        MIN(ss.ss_sold_date_sk) AS first_purchase_date,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
)
SELECT 
    hvc.c_customer_sk, 
    hvc.c_first_name, 
    hvc.c_last_name,
    pd.first_purchase_date,
    pd.last_purchase_date,
    hvc.total_purchases,
    hvc.total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY hvc.c_customer_sk ORDER BY hvc.total_net_profit DESC) AS purchase_rank,
    CASE 
        WHEN hvc.total_purchases > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_type
FROM high_value_customers hvc
LEFT JOIN purchase_dates pd ON hvc.c_customer_sk = pd.ss_customer_sk
WHERE pd.last_purchase_date IS NOT NULL
ORDER BY hvc.total_net_profit DESC
LIMIT 100;
