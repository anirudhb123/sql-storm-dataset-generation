
WITH RecursiveSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price > 0
    UNION ALL
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_order_number) AS rn
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sales_price IS NOT NULL
),
AddressCounts AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_customer_id
),
DemographicSales AS (
    SELECT
        d.cd_gender,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM
        customer_demographics d
    JOIN RecursiveSales ws ON d.cd_demo_sk = ws.ws_item_sk
    GROUP BY
        d.cd_gender
)
SELECT
    c.c_customer_id,
    ad.address_count,
    COALESCE(ds.cd_gender, 'Unknown') AS gender,
    COALESCE(ds.total_sales_value, 0) AS total_sales_value,
    CASE 
        WHEN ad.address_count = 1 THEN 'Single Address'
        WHEN ad.address_count BETWEEN 2 AND 5 THEN 'Multiple Addresses'
        ELSE 'Many Addresses'
    END AS address_type
FROM
    AddressCounts ad
LEFT JOIN customer c ON c.c_customer_id = ad.c_customer_id
LEFT JOIN DemographicSales ds ON ds.cd_gender = (
    SELECT 
        cd_gender 
    FROM customer_demographics 
    WHERE cd_demo_sk = c.c_current_cdemo_sk
    LIMIT 1
)
WHERE
    (ad.address_count IS NULL OR ad.address_count > 0) 
AND 
    (ds.total_sales_value IS NULL OR ds.total_sales_value > 1000)
ORDER BY
    ad.address_count DESC,
    c.c_customer_id;
