
WITH Recursive_CTE AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn,
        (
            SELECT COUNT(*)
            FROM store_sales ss
            WHERE ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
        ) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND (cd.cd_purchase_estimate > 5000 OR cd.cd_gender = 'F')
),
Purchase_Summary AS (
    SELECT
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.purchase_count,
        COALESCE(sm.sm_type, 'Unknown') AS preferred_ship_mode,
        COUNT(ws.ws_order_number) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
    FROM 
        Recursive_CTE r
    LEFT JOIN 
        web_sales ws ON r.c_customer_id = ws.ws_bill_customer_sk
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN 
        store_sales ss ON r.c_customer_id = ss.ss_customer_sk
    GROUP BY 
        r.c_customer_id, r.c_first_name, r.c_last_name, r.cd_gender, sm.sm_type
)

SELECT 
    p.*,
    d.d_year,
    RANK() OVER (PARTITION BY p.preferred_ship_mode ORDER BY p.total_web_sales DESC) AS web_sales_rank,
    CASE 
        WHEN p.purchase_count > 10 THEN 'High Value'
        WHEN p.purchase_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    Purchase_Summary p
JOIN 
    date_dim d ON (d.d_date_sk = (SELECT MAX(d1.d_date_sk) 
                                   FROM date_dim d1 
                                   WHERE d1.d_date = CURRENT_DATE))
WHERE 
    p.total_web_sales > 0
    AND (SELECT COUNT(*) FROM customer c1 WHERE c1.c_current_cdemo_sk = p.c_customer_id) > 1
ORDER BY 
    customer_value DESC, p.total_store_sales DESC;

WITH all_customers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)

SELECT
    ac.c_customer_sk,
    COALESCE(ac.total_web_orders, 0) AS total_web_orders,
    COALESCE(ac.total_store_orders, 0) AS total_store_orders,
    CASE 
        WHEN ac.total_web_orders > ac.total_store_orders THEN 'Web Dominant'
        WHEN ac.total_web_orders < ac.total_store_orders THEN 'Store Dominant'
        ELSE 'Equal'
    END AS sales_dominance
FROM 
    all_customers ac
WHERE 
    ac.total_web_orders > 0 OR ac.total_store_orders > 0
ORDER BY 
    COALESCE(ac.total_web_orders, 0) + COALESCE(ac.total_store_orders, 0) DESC;
