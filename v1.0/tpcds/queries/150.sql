
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.income_band,
    cd.purchase_rank
FROM 
    SalesSummary cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_id = (
        SELECT 
            c.c_customer_id 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk = (
                SELECT 
                    c.c_customer_sk 
                FROM 
                    customer c 
                WHERE 
                    c.c_current_cdemo_sk IS NOT NULL 
                    AND c.c_customer_id = cs.c_customer_id
        )
    )
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_sales DESC;
