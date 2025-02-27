
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        r.web_site_sk,
        SUM(r.ws_net_paid) AS total_net_paid,
        SUM(r.ws_quantity) AS total_quantity,
        COUNT(DISTINCT r.ws_item_sk) AS unique_items_sold
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.web_site_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_marital_status,
    ca.ca_city,
    ss.total_net_paid,
    ss.total_quantity,
    ss.unique_items_sold
FROM 
    CustomerData c
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT ca_address_sk FROM customer WHERE c_customer_sk = c.c_customer_sk)
JOIN 
    SalesSummary ss ON c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
WHERE 
    (c.cd_gender = 'F' AND c.cd_purchase_estimate > 5000) 
    OR (c.cd_gender = 'M' AND c.cd_purchase_estimate < 3000)
ORDER BY 
    ss.total_net_paid DESC, c.c_last_name, c.c_first_name;
