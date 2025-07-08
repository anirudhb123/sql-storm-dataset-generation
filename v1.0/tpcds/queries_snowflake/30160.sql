
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(CASE 
                WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 1 
                ELSE 0 
            END) AS married_female,
        SUM(CASE 
                WHEN cd.cd_marital_status = 'S' THEN 1 
                ELSE 0 
            END) AS single_male
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.customer_count,
    SUM(CASE WHEN sd.rn <= 5 THEN sd.ws_net_paid ELSE 0 END) AS top_sales_amounts,
    d.married_female,
    d.single_male
FROM 
    AddressDetails a
LEFT JOIN 
    SalesCTE sd ON a.customer_count > 0
LEFT JOIN 
    CustomerDemographics d ON d.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk LIMIT 1)
GROUP BY 
    a.ca_city, a.ca_state, a.customer_count, d.married_female, d.single_male
ORDER BY 
    a.customer_count DESC,
    top_sales_amounts DESC;
