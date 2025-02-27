
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM 
        customer_address ca
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_quantity,
    ss.total_sales,
    ai.full_address,
    COALESCE(ib.ib_income_band_sk, -1) AS income_band,
    CASE 
        WHEN ci.purchase_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    customer_info ci
JOIN 
    store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
LEFT JOIN 
    household_demographics hd ON ci.c_current_cdemo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    AND ci.cd_marital_status IS NOT NULL
ORDER BY 
    ss.total_sales DESC;
