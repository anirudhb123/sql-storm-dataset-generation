
WITH RECURSIVE demographic_analysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rn
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        (CASE 
            WHEN cd.cd_marital_status = 'M' AND cd.cd_gender = 'F' THEN 'Married Female'
            WHEN cd.cd_marital_status = 'M' AND cd.cd_gender = 'M' THEN 'Married Male'
            ELSE 'Others'
        END) AS marital_category,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_purchases,
        (SELECT SUM(cs_ext_net_profit) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS catalog_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        demographic_analysis cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (c.c_birth_year BETWEEN 1970 AND 1990 OR ca.ca_city IS NULL)
        AND cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
        AND cd.rn <= 5
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.marital_category,
    COUNT(ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    MAX(ws.ws_sales_price) AS highest_web_sales_price,
    STRING_AGG(DISTINCT ca.ca_street_name || ' ' || ca.ca_street_number, ', ') AS address_history
FROM 
    customer_details cd
LEFT JOIN 
    web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_address ca ON cd.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.marital_category
HAVING 
    COUNT(ws.ws_order_number) > 0 
    OR SUM(ws.ws_net_profit) IS NOT NULL
ORDER BY 
    total_web_net_profit DESC 
FETCH FIRST 10 ROWS ONLY;
