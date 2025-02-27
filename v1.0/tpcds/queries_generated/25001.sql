
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        CHAR_LENGTH(ca_street_name) AS char_length_street_name,
        CASE 
            WHEN ca_street_type IS NOT NULL THEN UPPER(ca_street_type) 
            ELSE 'UNKNOWN' 
        END AS normalized_street_type
    FROM 
        customer_address
),
AddressStats AS (
    SELECT 
        AVG(street_name_length) AS avg_street_name_length,
        COUNT(DISTINCT normalized_street_type) AS unique_street_types,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT full_address) AS unique_addresses
    FROM 
        AddressParts
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesOverview AS (
    SELECT 
        SUM(ws_net_profit) AS total_web_sales_profit,
        SUM(cs_net_profit) AS total_catalog_sales_profit,
        SUM(ss_net_profit) AS total_store_sales_profit
    FROM 
        web_sales AS ws
    FULL OUTER JOIN 
        catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        store_sales AS ss ON ws.ws_item_sk = ss.ss_item_sk
)
SELECT 
    AS.address_stats.avg_street_name_length,
    AS.address_stats.unique_street_types,
    AS.address_stats.total_addresses,
    AS.address_stats.unique_addresses,
    CS.gender_stats.cd_gender,
    CS.gender_stats.customer_count,
    CS.gender_stats.total_dependents,
    SO.total_web_sales_profit,
    SO.total_catalog_sales_profit,
    SO.total_store_sales_profit
FROM 
    AddressStats AS AS,
    CustomerStats AS CS,
    SalesOverview AS SO
WHERE 
    CS.cd_gender = 'F' OR CS.cd_gender = 'M';
