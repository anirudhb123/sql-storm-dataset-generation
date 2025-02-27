
WITH AddressCount AS (
    SELECT 
        ca_county,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city || ', ' || ca_state || ' ' || ca_zip, '; ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_county
),
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        STRING_AGG(DISTINCT ws_order_number::text, ', ') AS order_numbers
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        ac.ca_county,
        ac.address_count,
        ac.address_list,
        ds.avg_purchase_estimate,
        ds.demographic_count,
        sd.total_net_profit,
        sd.order_numbers
    FROM 
        AddressCount ac
    JOIN 
        DemographicStats ds ON ds.avg_purchase_estimate IS NOT NULL
    JOIN 
        SalesData sd ON sd.ws_bill_customer_sk IS NOT NULL
)
SELECT 
    *,
    COALESCE(address_count, 0) AS total_addresses,
    COALESCE(total_net_profit, 0) AS net_profit
FROM 
    FinalBenchmark
WHERE 
    total_net_profit > 0
ORDER BY 
    total_net_profit DESC, address_count DESC;
