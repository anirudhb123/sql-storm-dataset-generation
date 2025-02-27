
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(CAST(NULLIF(cd.cd_credit_rating, '') AS VARCHAR), 'UNKNOWN') AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY ca.ca_city) AS country_rank
    FROM 
        customer_address AS ca
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS avg_price
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_item_sk
),
returned_info AS (
    SELECT 
        CASE 
            WHEN sr_return_quantity IS NULL THEN 0 
            ELSE SUM(sr_return_quantity) 
        END AS total_returns,
        sr_customer_sk,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_returned_amount
    FROM 
        store_returns AS sr
    GROUP BY 
        sr_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.credit_rating,
    ai.full_address,
    si.total_quantity,
    si.total_sales,
    si.max_price,
    si.avg_price,
    ri.total_returns,
    ri.total_returned_amount,
    CASE 
        WHEN ri.total_returns IS NULL THEN 'NO RETURNS'
        ELSE 'HAS RETURNS'
    END AS return_status
FROM 
    customer_info AS ci
LEFT JOIN 
    address_info AS ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN 
    sales_info AS si ON si.ws_item_sk = ci.c_customer_sk
LEFT JOIN 
    returned_info AS ri ON ri.sr_customer_sk = ci.c_customer_sk
WHERE 
    (ci.gender_rank BETWEEN 1 AND 5 OR ai.country_rank < 10)
    AND (ri.total_returned_amount > 100 OR COALESCE(ri.total_returns, 0) = 0)
ORDER BY 
    ci.c_first_name, ci.c_last_name;
