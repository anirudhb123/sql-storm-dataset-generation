
WITH AddressCityData AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city
),
SalesData AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
CombinedData AS (
    SELECT 
        ac.ca_city,
        ac.customer_count,
        ac.customer_names,
        ac.male_count,
        ac.female_count,
        sd.total_sales,
        sd.total_profit
    FROM 
        AddressCityData AS ac
    LEFT JOIN 
        SalesData AS sd ON ac.ca_city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = sd.ws_bill_addr_sk)
)
SELECT 
    ca_city,
    customer_count,
    customer_names,
    male_count,
    female_count,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_profit, 0) AS total_profit
FROM 
    CombinedData
ORDER BY 
    customer_count DESC,
    total_sales DESC;
