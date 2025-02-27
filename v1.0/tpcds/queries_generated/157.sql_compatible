
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        csa.c_customer_id,
        csa.total_net_paid,
        csa.total_transactions
    FROM 
        CustomerSales csa
    WHERE 
        csa.total_net_paid > (
            SELECT 
                AVG(total_net_paid) 
            FROM 
                CustomerSales
        )
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hdh.hd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' THEN 'Married Male'
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Female'
            WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'S' THEN 'Single Male'
            ELSE 'Single Female'
        END AS demographic_group
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hdh ON cd.cd_demo_sk = hdh.hd_demo_sk
),
FinalAnalysis AS (
    SELECT 
        hs.c_customer_id,
        cd.demographic_group,
        hs.total_net_paid,
        hs.total_transactions,
        ROW_NUMBER() OVER (PARTITION BY cd.demographic_group ORDER BY hs.total_net_paid DESC) AS demographic_rank
    FROM 
        HighSpenders hs
    JOIN 
        CustomerDemographics cd ON hs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    fa.demographic_group,
    COUNT(fa.c_customer_id) AS number_of_customers,
    AVG(fa.total_net_paid) AS avg_total_net_paid,
    MAX(fa.total_net_paid) AS max_total_net_paid
FROM 
    FinalAnalysis fa
GROUP BY 
    fa.demographic_group
HAVING 
    COUNT(fa.c_customer_id) > 1
ORDER BY 
    avg_total_net_paid DESC;
