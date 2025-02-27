
WITH RankedSales AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.sold_date_sk, ws.item_sk
), 
CustomerInfo AS (
    SELECT 
        c.customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL 
        AND (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
), 
TopItems AS (
    SELECT 
        item_sk,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    ci.customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.item_sk,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(NULLIF(ci.cd_purchase_estimate, 0), 1) AS adjusted_estimate,
    CASE 
        WHEN ci.cd_credit_rating IN ('Excellent', 'Good') THEN 'High Value'
        ELSE 'General'
    END AS customer_value
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopItems ti ON ci.c_current_cdemo_sk = ti.item_sk
ORDER BY 
    ti.total_sales DESC, 
    ci.cd_gender ASC;
