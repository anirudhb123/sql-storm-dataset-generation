
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS demographic_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    rs.total_quantity,
    rs.total_sales_price
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedSales rs ON cd.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = rs.ws_item_sk LIMIT 1)
WHERE 
    cd.demographic_rank <= 10 AND 
    cd.cd_marital_status = 'M' AND 
    cd.cd_credit_rating IS NOT NULL
ORDER BY 
    rs.total_sales_price DESC
LIMIT 100;
