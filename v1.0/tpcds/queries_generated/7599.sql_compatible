
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_net_profit
    FROM ranked_sales cs
    JOIN customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    WHERE cs.profit_rank <= 10
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        t.total_quantity,
        t.total_net_profit
    FROM top_customers t
    JOIN customer_demographics cd ON t.c_customer_id = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    AVG(cd.total_quantity) AS avg_quantity,
    AVG(cd.total_net_profit) AS avg_net_profit
FROM customer_demographics cd
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY avg_net_profit DESC;
