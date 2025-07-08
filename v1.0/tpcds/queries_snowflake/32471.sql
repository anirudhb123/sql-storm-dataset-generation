
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer AS c 
    LEFT JOIN 
        web_sales AS ws 
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, 
        c.c_customer_id
    UNION ALL
    SELECT 
        ch.c_customer_sk, 
        ch.c_customer_id, 
        0 AS total_sales
    FROM 
        customer AS ch 
    JOIN 
        sales_hierarchy AS sh 
        ON sh.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN 
        web_sales AS ws 
        ON ch.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        ch.c_customer_sk, 
        ch.c_customer_id
),
customer_return_info AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(cr.cr_order_number) AS total_orders_returned
    FROM 
        catalog_returns AS cr
    GROUP BY 
        cr.cr_returning_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM 
        customer_address AS ca
),
customer_demo_stats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd.cd_dep_count) AS min_dependents,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c 
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    sh.c_customer_id,
    SUM(sh.total_sales) AS total_sales,
    COALESCE(ci.total_returned, 0) AS total_returned,
    COALESCE(ci.total_orders_returned, 0) AS total_orders_returned,
    a.full_address,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ds.min_dependents,
    ds.max_dependents
FROM 
    sales_hierarchy AS sh
LEFT JOIN 
    customer_return_info AS ci 
    ON sh.c_customer_sk = ci.cr_returning_customer_sk
LEFT JOIN 
    address_info AS a 
    ON sh.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    customer_demo_stats AS ds 
    ON sh.c_customer_sk = ds.cd_demo_sk
WHERE 
    sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy) 
    AND a.full_address IS NOT NULL
GROUP BY 
    sh.c_customer_id,
    a.full_address,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ds.min_dependents,
    ds.max_dependents
ORDER BY 
    total_sales DESC
LIMIT 100;
