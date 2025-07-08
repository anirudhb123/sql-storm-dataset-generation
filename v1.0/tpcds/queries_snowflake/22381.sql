WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c_current_cdemo_sk,
        CAST(1 AS INTEGER) AS lvl
    FROM 
        customer c
    WHERE 
        c.c_birth_month = COALESCE(NULLIF(EXTRACT(MONTH FROM cast('2002-10-01' as date)), 0), 1)

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_current_cdemo_sk,
        lvl + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk 
    WHERE 
        ch.lvl < 5
),

customer_estimates AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cd.cd_purchase_estimate, 0)) AS total_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    cca.c_first_name,
    cca.c_last_name,
    cde.total_purchase_estimate,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male' 
        WHEN cd.cd_gender = 'F' THEN 'Female' 
        ELSE 'Other' 
    END AS gender,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cde.total_purchase_estimate DESC) AS ranking,
    COALESCE(NULLIF(cd.cd_credit_rating, ''), 'Unknown') AS credit_rating
FROM 
    customer_hierarchy cca
JOIN 
    customer_estimates cde ON cca.c_current_cdemo_sk = cde.cd_demo_sk
JOIN 
    customer_demographics cd ON cca.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_bill_cdemo_sk = cde.cd_demo_sk 
        AND ws.ws_sold_date_sk = (
            SELECT MAX(ws_inner.ws_sold_date_sk) 
            FROM web_sales ws_inner 
            WHERE ws_inner.ws_bill_cdemo_sk = cde.cd_demo_sk
        )
    )
AND 
    cde.customer_count > (
        SELECT AVG(customer_count) 
        FROM customer_estimates 
        WHERE cd_gender = cd.cd_gender
    )
ORDER BY 
    cca.c_first_name, cca.c_last_name;