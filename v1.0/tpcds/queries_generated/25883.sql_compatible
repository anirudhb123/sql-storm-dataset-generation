
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' ', ca.ca_suite_number), ''), ', ', ca.ca_city, ', ', ca.ca_state, ' ', 
               ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
DemographicSummary AS (
    SELECT 
        cd.cd_demo_sk, 
        COUNT(c.c_customer_sk) AS customer_count, 
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd.cd_gender) AS gender_distribution,
        STRING_AGG(DISTINCT cd.cd_marital_status) AS marital_status_distribution
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_tax) AS total_tax_amount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ad.full_address, 
    ds.customer_count, 
    ds.max_purchase_estimate, 
    ds.min_purchase_estimate, 
    ds.avg_purchase_estimate, 
    ds.gender_distribution, 
    ds.marital_status_distribution,
    sd.total_quantity_sold, 
    sd.total_sales_amount,
    sd.total_tax_amount,
    sd.total_profit,
    sd.order_count
FROM 
    AddressDetails ad
JOIN 
    DemographicSummary ds ON ad.ca_address_sk = (SELECT ca.ca_address_sk FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk LIMIT 1) 
JOIN 
    SalesData sd ON sd.ws_item_sk = (SELECT i.i_item_sk FROM item i LIMIT 1)
WHERE 
    ad.full_address IS NOT NULL
ORDER BY 
    ds.customer_count DESC;
