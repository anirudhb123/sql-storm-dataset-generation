
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000
        AND cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
), 
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.total_net_profit,
        CASE 
            WHEN rc.gender_rank <= 5 THEN 'Top 5'
            ELSE 'Others'
        END AS rank_category
    FROM 
        ranked_customers rc
    WHERE 
        rc.gender_rank <= 10
)
SELECT 
    tc.rank_category,
    COUNT(tc.c_customer_sk) AS customer_count,
    AVG(tc.total_net_profit) AS avg_net_profit,
    STRING_AGG(CONCAT(tc.c_first_name, ' ', tc.c_last_name), ', ') AS customer_names
FROM 
    top_customers tc
GROUP BY 
    tc.rank_category
ORDER BY 
    avg_net_profit DESC
