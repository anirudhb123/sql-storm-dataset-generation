
WITH ranked_sales AS (
    SELECT 
        ws.bill_cdemo_sk,
        SUM(ws.net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.bill_cdemo_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        ws.bill_cdemo_sk
),
customer_data AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        rg.total_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        ranked_sales rg ON cd.cd_demo_sk = rg.bill_cdemo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(cd.total_sales) AS avg_sales
FROM 
    customer_data cd
WHERE 
    cd.total_sales IS NOT NULL
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(*) > 5
ORDER BY 
    avg_sales DESC
LIMIT 10;
