
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicCounts AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demo_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales AS ws
    JOIN 
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
),
FinalResults AS (
    SELECT 
        ac.ca_city,
        ac.address_count,
        dc.cd_gender,
        dc.demo_count,
        ss.web_site_id,
        ss.total_net_profit,
        ss.total_net_paid
    FROM 
        AddressCounts AS ac
    CROSS JOIN 
        DemographicCounts AS dc
    LEFT JOIN 
        SalesSummary AS ss ON dc.demo_count > 0
)
SELECT 
    * 
FROM 
    FinalResults
WHERE 
    address_count > 5 
    AND total_net_profit > 1000
ORDER BY 
    address_count DESC, 
    total_net_profit DESC;
