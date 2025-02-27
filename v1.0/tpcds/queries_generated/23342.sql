
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) as sales_rank
    FROM
        web_sales ws
    WHERE
        ws_sold_date_sk BETWEEN 10101 AND 10130
),
HighValueCustomers AS (
    SELECT 
        cd_demo_sk, 
        SUM(CASE WHEN sales_rank = 1 THEN ws_sales_price ELSE 0 END) as highest_sales
    FROM 
        RankedSales rs
    JOIN customer c ON rs.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk
    HAVING SUM(ws_sales_price) > 500
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CASE WHEN ca.ca_country IS NULL THEN 'Unknown' ELSE ca.ca_country END as country
    FROM
        customer_address ca
    WHERE 
        EXISTS (SELECT 1 FROM HighValueCustomers hvc WHERE hvc.cd_demo_sk = ca.ca_address_sk)
),
AggregateSales AS (
    SELECT 
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.country,
    COALESCE(ag.total_sales, 0) AS total_sales,
    COALESCE(ag.unique_customers, 0) AS unique_customers
FROM 
    CustomerAddresses ca
LEFT JOIN 
    AggregateSales ag ON ca.ca_zip = ag.unique_customers::text
WHERE 
    (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL)
    AND ca.ca_state NOT IN ('NY', 'CA')
ORDER BY 
    total_sales DESC NULLS LAST;
