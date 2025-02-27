
WITH RECURSIVE CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.ws_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_tax, 0) AS total_tax
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
),
AddressWithCustomerCount AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    i.item_desc,
    is.total_quantity,
    is.total_sales,
    is.total_tax,
    ac.customer_count,
    (is.total_sales - is.total_tax) AS net_sales_after_tax,
    CASE 
        WHEN cd.cd_purchase_estimate > 5000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CustomerData cd
JOIN ItemSales is ON cd.rn = 1
JOIN AddressWithCustomerCount ac ON ac.customer_count > 5
WHERE cd.rn = 1 OR cd.cd_gender IS NULL
ORDER BY net_sales_after_tax DESC
LIMIT 100;
