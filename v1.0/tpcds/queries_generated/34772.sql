
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
    UNION ALL
    SELECT 
        d_year,
        SUM(ws_net_profit) * 1.05 AS total_profit -- assuming a growth of 5%
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year < (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        d_year
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
FilteredCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.total_spent,
        CASE 
            WHEN ci.total_spent IS NULL THEN 'No Purchases' 
            WHEN ci.total_spent > 1000 THEN 'High Value' 
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerInfo ci
    WHERE 
        ci.total_spent IS NOT NULL OR ci.total_spent < 1000
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.cd_gender,
    fc.customer_type,
    sg.total_profit
FROM 
    FilteredCustomers fc
CROSS JOIN 
    (SELECT AVG(total_profit) AS avg_profit FROM SalesGrowth) sg
WHERE 
    (sg.avg_profit > 50000 OR fc.total_spent > 500) 
    AND (fc.cd_gender IS NOT NULL OR fc.total_spent IS NOT NULL)
ORDER BY 
    fc.c_last_name, fc.c_first_name;
