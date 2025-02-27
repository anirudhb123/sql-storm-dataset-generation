
WITH ranked_returns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS return_rank
    FROM
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT CASE WHEN cd.cd_dep_college_count > 0 THEN cd.cd_demo_sk END) AS college_dependents,
        COUNT(DISTINCT CASE WHEN cd.cd_dep_employed_count > 0 THEN cd.cd_demo_sk END) AS employed_dependents,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY COUNT(c.c_customer_id) DESC) AS gender_marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND cd.cd_credit_rating IS NOT NULL 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
total_shipping_cost AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_ext_ship_cost) AS total_shipping
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
combined_data AS (
    SELECT 
        cd.c_customer_id,
        cd.max_purchase_estimate,
        cd.college_dependents,
        cd.employed_dependents,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(ts.total_shipping, 0) AS total_shipping_cost
    FROM 
        customer_details cd
    LEFT JOIN 
        ranked_returns rr ON rr.cr_returning_customer_sk = cd.c_customer_id
    LEFT JOIN 
        total_shipping_cost ts ON ts.ws_ship_customer_sk = cd.c_customer_id
)
SELECT 
    c.c_customer_id, 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.max_purchase_estimate,
    cd.college_dependents,
    cd.employed_dependents,
    cd.total_returned,
    cd.total_shipping_cost,
    CASE 
        WHEN cd.total_returned > 0 AND cd.total_shipping_cost > 0 THEN 'Returns and Ship Costs' 
        WHEN cd.total_returned > 0 THEN 'Returns Only'
        WHEN cd.total_shipping_cost > 0 THEN 'Shipping Costs Only'
        ELSE 'No Returns or Shipping'
    END AS return_shipping_status
FROM 
    combined_data cd
JOIN 
    customer c ON c.c_customer_id = cd.c_customer_id
WHERE 
    (cd.total_returned > 50 OR cd.total_shipping_cost IS NULL)
    AND cd.max_purchase_estimate BETWEEN (SELECT MIN(cd_purchase_estimate) FROM customer_demographics) 
                                    AND (SELECT MAX(cd_purchase_estimate) FROM customer_demographics)
ORDER BY 
    cd.max_purchase_estimate DESC, cd.total_returned, cd.total_shipping_cost
FETCH FIRST 100 ROWS ONLY;
