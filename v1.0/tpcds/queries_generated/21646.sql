
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON ch.c_current_cdemo_sk = c.c_customer_sk
),
SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BYSUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        SUBSTRING(ca.ca_street_name, 1, 10) AS street_prefix,
        COALESCE(ca.ca_city, 'UNKNOWN') AS city_name,
        ca.ca_state AS state_code,
        CASE 
            WHEN ca.ca_zip LIKE '%.0%' THEN NULL ELSE ca.ca_zip 
        END AS sanitized_zip
    FROM 
        customer_address ca
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    addr.street_prefix,
    addr.city_name,
    addr.state_code,
    CASE 
        WHEN s.total_profit IS NULL THEN 'No Sales' 
        ELSE CAST(s.total_profit AS VARCHAR) 
    END AS total_profit,
    s.order_count,
    CASE 
        WHEN s.order_count >= 5 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS customer_type
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    SalesStatistics s ON ch.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    AddressInfo addr ON ch.c_current_cdemo_sk = addr.ca_address_sk
WHERE 
    (s.total_profit IS NOT NULL OR addr.city_name IS NOT NULL)
    AND ((ch.level >= 1 AND ch.level <= 5) 
         OR (s.order_count IS NULL AND addr.state_code != 'NY'))
ORDER BY 
    ch.c_first_name, ch.c_last_name;
