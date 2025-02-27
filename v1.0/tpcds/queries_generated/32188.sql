
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_month IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        sh.total_profit + SUM(ws.ws_net_profit)
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        SalesHierarchy sh ON c.c_birth_month = sh.c_birth_month AND c.c_birth_year = sh.c_birth_year
    GROUP BY 
        c.c_customer_sk, sh.total_profit, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year
),
FilteredSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY sh.c_birth_month ORDER BY sh.total_profit DESC) AS rank
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        customer_address ca ON sh.c_customer_sk = ca.ca_address_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_profit,
    fs.ca_city,
    fs.ca_state
FROM 
    FilteredSales fs
WHERE 
    fs.rank <= 10 
    AND fs.total_profit IS NOT NULL 
    AND (fs.ca_state = 'NY' OR fs.ca_city IS NOT NULL)
ORDER BY 
    fs.total_profit DESC
LIMIT 50;
