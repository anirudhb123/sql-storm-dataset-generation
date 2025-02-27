
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
WebSalesAnalysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        DATE(ws_sold_date_sk) BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ra.ca_address_sk,
        ra.ca_city,
        ra.ca_state,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.customer_count,
        cs.avg_purchase_estimate,
        wa.total_profit,
        wa.total_orders
    FROM 
        RankedAddresses ra
    JOIN 
        CustomerStats cs ON ra.city_rank = 1
    JOIN 
        WebSalesAnalysis wa ON ra.ca_address_sk = wa.ws_bill_customer_sk
)

SELECT 
    fa.ca_city,
    fa.ca_state,
    fa.cd_gender,
    fa.cd_marital_status,
    fa.customer_count,
    fa.avg_purchase_estimate,
    fa.total_profit,
    fa.total_orders
FROM 
    FinalReport fa
ORDER BY 
    fa.total_profit DESC
LIMIT 100;
