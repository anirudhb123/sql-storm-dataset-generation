
WITH StringAggregates AS (
    SELECT 
        ca_state,
        LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS CustomerNames,
        LISTAGG(DISTINCT ca_city, '; ') WITHIN GROUP (ORDER BY ca_city) AS UniqueCities,
        COUNT(DISTINCT c_customer_sk) AS TotalCustomers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state
), 
PurchaseStatistics AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        SUM(ws_net_profit) AS TotalNetProfit
    FROM 
        customer_demographics cd
    JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    sa.ca_state,
    sa.CustomerNames,
    sa.UniqueCities,
    sa.TotalCustomers,
    ps.AvgPurchaseEstimate,
    ps.TotalNetProfit
FROM 
    StringAggregates sa
JOIN 
    PurchaseStatistics ps ON sa.TotalCustomers > 0
ORDER BY 
    sa.ca_state;
