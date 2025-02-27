
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_profit > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    AND 
        c.c_customer_sk NOT IN (SELECT c_customer_sk FROM Sales_CTE)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_profit > 1000
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.gender,
    s.marital_status,
    s.credit_rating,
    s.order_count,
    s.total_net_profit,
    t.t_hour,
    COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns
FROM 
    Customer_Summary s
JOIN 
    time_dim t ON t.t_time_sk = (SELECT MIN(ws.ws_sold_time_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = s.c_customer_sk)
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = s.c_customer_sk
GROUP BY 
    s.c_first_name, s.c_last_name, s.gender, s.marital_status, s.credit_rating, s.order_count, s.total_net_profit, t.t_hour
HAVING 
    s.order_count > 5 AND 
    total_returns > 100
ORDER BY 
    s.total_net_profit DESC;
