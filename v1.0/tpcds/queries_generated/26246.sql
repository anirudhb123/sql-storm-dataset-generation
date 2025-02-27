
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    WHERE 
        c.c_birth_year > 1980 -- Only customers born after 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    first_name,
    last_name,
    gender,
    marital_status,
    total_spent
FROM 
    RankedSales
WHERE 
    sales_rank <= 5 -- Top 5 customers per gender
ORDER BY 
    gender, total_spent DESC;
