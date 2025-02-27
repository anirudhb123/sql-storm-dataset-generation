
WITH RankedSales AS (
    SELECT 
        s_store_sk, 
        ss_sold_date_sk, 
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_profit_rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
SalesWithDemographics AS (
    SELECT 
        ss.sold_date_sk,
        cs.s_customer_sk,
        cs.total_quantity_sold,
        cd.avg_purchase_estimate,
        CASE 
            WHEN cd.avg_purchase_estimate > 10000 THEN 'High Value'
            WHEN cd.avg_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        store_sales ss
    JOIN 
        RankedSales cs ON ss.ss_store_sk = cs.s_store_sk AND ss.ss_sold_date_sk = cs.ss_sold_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.total_profit > 1000
),
FinalReport AS (
    SELECT 
        customer_value_segment,
        COUNT(DISTINCT cs.s_customer_sk) AS customer_count,
        SUM(cs.total_quantity_sold) AS total_quantity,
        SUM(cs.total_profit) AS total_profit
    FROM 
        SalesWithDemographics cs
    GROUP BY 
        customer_value_segment
)
SELECT 
    customer_value_segment,
    customer_count,
    total_quantity,
    total_profit,
    ROUND((total_profit / NULLIF(total_quantity, 0)), 2) AS avg_profit_per_item
FROM 
    FinalReport
ORDER BY 
    total_profit DESC;
