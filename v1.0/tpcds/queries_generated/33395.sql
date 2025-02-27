
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
    HAVING SUM(ws.ws_net_profit) IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE wr.wr_return_amount > 0
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)

SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    SUM(sh.total_profit) AS adjusted_profit,
    DENSE_RANK() OVER (ORDER BY SUM(sh.total_profit) DESC) AS profit_rank,
    CASE 
        WHEN sh.cd_gender = 'M' THEN 'Male'
        WHEN sh.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender_label,
    COALESCE(NULLIF(sh.cd_marital_status, 'S'), 'Single') AS marital_status
FROM sales_hierarchy sh
WHERE sh.total_profit > 0
GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.cd_gender, sh.cd_marital_status
ORDER BY adjusted_profit DESC
LIMIT 10;
