
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 60
    GROUP BY 
        ss_store_sk
),
SalesDetails AS (
    SELECT 
        s.s_store_name,
        s.s_state,
        rs.total_transactions,
        rs.total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        store s ON rs.ss_store_sk = s.s_store_sk
    WHERE 
        rs.rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd_cd_purchase_estimate,
        SUM(sd.total_net_profit) AS total_profit_per_demographic
    FROM 
        SalesDetails sd
    JOIN 
        customer c ON sd.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS demographic_count,
    SUM(cd.total_profit_per_demographic) AS aggregate_profit
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    aggregate_profit DESC;
