
WITH RECURSIVE sales_growth AS (
    SELECT
        d.d_year,
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        date_dim d
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year,
        SUM(cs.net_profit) AS total_net_profit
    FROM 
        date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        customer c
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        customer_net_profit DESC
    LIMIT 10
),
state_sales AS (
    SELECT
        ca.ca_state,
        SUM(ss.ss_net_profit) AS state_total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN DATE '2020-01-01' AND DATE '2023-12-31'
    GROUP BY 
        ca.ca_state
)
SELECT 
    t.year AS sales_year,
    tg.total_net_profit,
    tc.c_first_name,
    tc.c_last_name,
    ss.ca_state,
    ss.state_total_net_profit,
    ss.unique_customers
FROM 
    (SELECT 
         d_year AS year, 
         SUM(total_net_profit) AS total_net_profit 
     FROM 
         sales_growth 
     GROUP BY d_year) tg
FULL OUTER JOIN top_customers tc ON TRUE
FULL OUTER JOIN state_sales ss ON 1=1
ORDER BY 
    sales_year DESC, 
    state_total_net_profit DESC;
