
WITH sales_summary AS (
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
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
recursive_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_profit
    FROM 
        sales_summary c
    UNION ALL
    SELECT 
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        SUM(ss.total_profit) AS total_profit
    FROM 
        recursive_sales ss
    JOIN 
        store_sales st ON ss.c_customer_sk = st.ss_customer_sk
    WHERE 
        st.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND st.ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.c_customer_sk, ss.c_first_name, ss.c_last_name
),
profitable_customers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_profit,
        ROW_NUMBER() OVER (PARTITION BY s.c_customer_sk ORDER BY s.total_profit DESC) AS rank
    FROM 
        recursive_sales s
    WHERE 
        s.total_profit > 0
)
SELECT 
    pc.c_customer_sk,
    pc.c_first_name,
    pc.c_last_name,
    pc.total_profit
FROM 
    profitable_customers pc
WHERE 
    pc.rank = 1
AND EXISTS (
    SELECT 1 
    FROM customer_demographics cd 
    WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = pc.c_customer_sk) 
    AND cd.cd_marital_status = 'M'
)
ORDER BY 
    pc.total_profit DESC;
