
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressAggregates AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        STRING_AGG(DISTINCT CONCAT_WS(' ', c.c_first_name, c.c_last_name)) AS customer_names
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    rc.c_customer_id,
    aa.ca_city,
    sd.total_quantity,
    sd.total_net_profit,
    CASE 
        WHEN sd.total_net_profit IS NULL THEN 'No Profit'
        WHEN sd.total_net_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM 
    RankedCustomers rc
LEFT OUTER JOIN 
    AddressAggregates aa ON rc.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = aa.ca_address_sk)
LEFT JOIN 
    SalesData sd ON rc.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk)
WHERE 
    rc.rnk = 1
  AND 
    (sd.total_quantity IS NULL OR sd.total_quantity > 0)
ORDER BY 
    profit_category DESC, rc.c_customer_id;
