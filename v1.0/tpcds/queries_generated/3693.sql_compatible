
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_spend,
        SUM(cs.cs_net_paid) AS total_catalog_spend,
        SUM(ss.ss_net_paid) AS total_store_spend,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spend
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000
),
RankedDemographics AS (
    SELECT 
        cd.*, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        CustomerDemographics cd
    WHERE 
        cd.cd_gender IS NOT NULL
)
SELECT 
    cs.c_customer_sk,
    cs.total_spend,
    rd.cd_gender,
    rd.cd_marital_status,
    rd.cd_purchase_estimate
FROM 
    CustomerSpend cs
LEFT JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    RankedDemographics rd ON c.c_current_cdemo_sk = rd.cd_demo_sk
WHERE 
    cs.total_spend > 5000
    AND (rd.cd_marital_status = 'M' OR rd.cd_gender = 'F')
    AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk = (
            SELECT sr.s_store_sk 
            FROM store_returns sr 
            WHERE sr.sr_customer_sk = cs.c_customer_sk
            LIMIT 1
        )
    )
ORDER BY 
    cs.total_spend DESC;
