
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sales_price,
        ss_quantity,
        ss_net_profit,
        1 AS level,
        CAST(s_store_sk AS VARCHAR) AS path
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)

    UNION ALL

    SELECT 
        sh.s_store_sk,
        sh.ss_sales_price * 1.05 AS ss_sales_price,
        sh.ss_quantity,
        sh.ss_net_profit * 1.10 AS ss_net_profit,
        level + 1,
        path || ' -> ' || CAST(sh.s_store_sk AS VARCHAR)
    FROM 
        store_sales AS sh
    JOIN 
        sales_hierarchy AS shier ON sh.s_store_sk = shier.s_store_sk
    WHERE 
        level < 5
),

avg_sales AS (
    SELECT 
        s_store_sk,
        AVG(ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_fy_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_fy_year = 2023)
    GROUP BY 
        s_store_sk
),

customer_stats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
)

SELECT 
    h.s_store_sk,
    AVG(h.ss_net_profit) AS average_store_profit,
    cs.cd_gender,
    cs.customer_count,
    cs.total_profit,
    ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY AVG(h.ss_net_profit) DESC) AS rank
FROM 
    sales_hierarchy h
JOIN 
    avg_sales a ON h.s_store_sk = a.s_store_sk
JOIN 
    customer_stats cs ON cs.total_profit > 1000 
GROUP BY 
    h.s_store_sk, cs.cd_gender, cs.customer_count, cs.total_profit
HAVING 
    AVG(h.ss_net_profit) > 500
ORDER BY 
    average_store_profit DESC, cs.customer_count ASC;

