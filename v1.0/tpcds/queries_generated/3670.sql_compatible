
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 3000000 AND 3000310
    GROUP BY 
        ss_store_sk, ss_item_sk
),
HighVolumeStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        COUNT(DISTINCT ss_item_sk) AS item_count 
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
    HAVING 
        COUNT(DISTINCT ss_item_sk) > 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    hvs.s_store_name,
    R.total_quantity,
    R.total_net_paid,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No purchases'
        ELSE CAST(cs.total_spent AS VARCHAR) 
    END AS total_spent
FROM 
    HighVolumeStores hvs
JOIN 
    RankedSales R ON hvs.s_store_sk = R.ss_store_sk 
LEFT JOIN 
    CustomerStats cs ON R.ss_item_sk IN (SELECT ss_item_sk FROM store_sales ss WHERE ss.ss_customer_sk = cs.c_customer_sk)
WHERE 
    R.rank <= 5
ORDER BY 
    hvs.s_store_name, R.total_net_paid DESC;
