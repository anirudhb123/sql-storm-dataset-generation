
WITH RankedAddresses AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(ca.ca_address_sk) AS address_count,
        ROW_NUMBER() OVER (PARTITION BY ca.city ORDER BY COUNT(ca.ca_address_sk) DESC) AS city_rank
    FROM 
        customer_address ca
    GROUP BY 
        ca.city, ca.state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesPool AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ra.city,
    ra.state,
    ra.address_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_purchase_estimate,
    cd.customer_count,
    sp.d_year,
    sp.total_profit,
    sp.total_quantity_sold
FROM 
    RankedAddresses ra
JOIN 
    CustomerDemographics cd ON cd.customer_count > 100
JOIN 
    SalesPool sp ON sp.total_profit > 50000
WHERE 
    ra.city_rank = 1
ORDER BY 
    sp.total_profit DESC, ra.city;
