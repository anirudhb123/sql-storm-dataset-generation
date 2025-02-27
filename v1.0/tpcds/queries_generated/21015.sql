
WITH RECURSIVE income_per_month AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_profit) AS total_income,
        DATEADD(MONTH, -1, d.d_date) AS income_month
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= '2022-01-01' AND d.d_date < '2023-01-01'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, d.d_date
    UNION ALL
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_profit) AS total_income,
        DATEADD(MONTH, -1, ipm.income_month) AS income_month
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        income_per_month ipm ON c.c_customer_id = ipm.c_customer_id
    WHERE 
        d.d_date >= DATEADD(MONTH, -12, ipm.income_month) 
        AND d.d_date < ipm.income_month
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ipm.income_month
),
full_income_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(total_income), 0) AS total_income,
        COUNT(*) AS months_active
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_per_month ipm ON c.c_customer_id = ipm.c_customer_id 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_purchase_estimate,
    f.total_income,
    f.months_active,
    CASE 
        WHEN f.total_income > 10000 THEN 'High Income'
        WHEN f.total_income BETWEEN 5000 AND 10000 THEN 'Medium Income'
        ELSE 'Low Income'
    END AS income_category,
    CASE 
        WHEN f.departed_flag IS NOT NULL THEN 'Departed'
        ELSE 'Current'
    END AS customer_status,
    RANK() OVER (PARTITION BY f.cd_gender ORDER BY f.total_income DESC) AS gender_income_rank
FROM 
    full_income_data f
LEFT JOIN 
    (SELECT c.c_customer_id, c.c_birth_month = NULL AS departed_flag
     FROM customer c 
     WHERE c.c_birth_month IS NULL
    ) AS departed_customers ON f.c_customer_id = departed_customers.c_customer_id
ORDER BY 
    f.cd_gender, f.total_income DESC;
