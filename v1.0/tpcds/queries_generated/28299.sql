
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ss_customer_sk IS NOT NULL THEN 'Store' 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web' 
            WHEN cr_returning_customer_sk IS NOT NULL THEN 'Catalog'
        END AS sales_channel,
        COALESCE(ss_sales_price, ws_sales_price, cs_sales_price) AS total_sales,
        CASE 
            WHEN ss_sales_price IS NOT NULL THEN ss_store_sk 
            WHEN ws_sales_price IS NOT NULL THEN ws_web_site_sk 
            WHEN cs_sales_price IS NOT NULL THEN cs_call_center_sk
        END AS channel_sk
    FROM 
        store_sales AS ss
    FULL OUTER JOIN web_sales AS ws ON ss.ss_item_sk = ws.ws_item_sk
    FULL OUTER JOIN catalog_sales AS cs ON ss.ss_item_sk = cs.cs_item_sk
),
GenderDemographic AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
GroupedData AS (
    SELECT 
        ai.full_address,
        sd.sales_channel,
        gd.cd_gender,
        SUM(sd.total_sales) AS total_sales
    FROM 
        AddressInfo ai
    JOIN 
        SalesData sd ON sd.channel_sk = ai.ca_address_sk 
    JOIN 
        GenderDemographic gd ON sd.sales_channel IS NOT NULL 
    GROUP BY 
        ai.full_address, sd.sales_channel, gd.cd_gender
)
SELECT 
    full_address,
    sales_channel,
    cd_gender,
    total_sales,
    LENGTH(full_address) AS address_length,
    UPPER(full_address) AS upper_case_address,
    LOWER(full_address) AS lower_case_address
FROM 
    GroupedData
ORDER BY 
    total_sales DESC, address_length DESC;
