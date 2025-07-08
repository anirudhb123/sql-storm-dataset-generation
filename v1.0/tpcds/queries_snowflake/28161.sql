
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        cs_item_sk
),
CustomerSegments AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
        JOIN customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        LISTAGG(CONCAT(ca_city, ', ', ca_street_name), '; ') AS city_street_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
)
SELECT 
    R.cs_item_sk,
    R.total_quantity,
    R.total_sales,
    C.total_customers,
    C.male_count,
    C.female_count,
    A.unique_addresses,
    A.city_street_list
FROM 
    RankedSales R
JOIN 
    CustomerSegments C ON C.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_customer_sk = R.cs_item_sk LIMIT 1)
JOIN 
    AddressSummary A ON A.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = R.cs_item_sk LIMIT 1))
WHERE 
    R.rank = 1
ORDER BY 
    R.total_sales DESC;
