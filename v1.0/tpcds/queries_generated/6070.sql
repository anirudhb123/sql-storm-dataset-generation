
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS rank_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
), CustomerUnderstanding AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        SUM(ws.net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        RankedSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_income_band_sk, cd.cd_purchase_estimate
), IncomeAnalysis AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(total_spent) AS avg_spent
    FROM 
        CustomerUnderstanding cu
    JOIN 
        income_band ib ON cu.cd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ia.ib_income_band_sk,
    ia.customer_count,
    ia.avg_spent,
    SUM(ws.ws_quantity) AS total_quantity
FROM 
    IncomeAnalysis ia
JOIN 
    web_sales ws ON ia.ib_income_band_sk = ws.ws_ship_mode_sk
GROUP BY 
    ia.ib_income_band_sk, ia.customer_count, ia.avg_spent
ORDER BY 
    ia.ib_income_band_sk;
