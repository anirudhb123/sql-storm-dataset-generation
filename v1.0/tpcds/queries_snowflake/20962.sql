
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        CASE 
            WHEN c.c_birth_month IS NOT NULL THEN 
                CONCAT(EXTRACT(YEAR FROM '2002-10-01'::DATE) - c.c_birth_year, ' years old')
            ELSE 'Unknown age'
        END AS age_description,
        NULL AS parent_customer_sk
    FROM 
        customer c
    WHERE 
        c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        CASE 
            WHEN c.c_birth_month IS NOT NULL THEN 
                CONCAT(EXTRACT(YEAR FROM '2002-10-01'::DATE) - c.c_birth_year, ' years old')
            ELSE 'Unknown age'
        END AS age_description,
        ch.c_customer_sk AS parent_customer_sk
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE 
        c.c_customer_sk IS NOT NULL 
)

SELECT 
    cha.c_first_name AS child_first_name,
    cha.c_last_name AS child_last_name,
    cha.age_description AS child_age,
    p.p_promo_name,
    SUM(ws.ws_sales_price) AS total_sales,
    CASE 
        WHEN cha.c_birth_year < 1990 THEN 'Younger Customer'
        WHEN cha.c_birth_year BETWEEN 1980 AND 1990 THEN 'Middle-Aged Customer'
        ELSE 'Older Customer'
    END AS customer_age_group,
    LISTAGG(DISTINCT w.w_warehouse_name, ', ') AS associated_warehouses
FROM 
    customer_hierarchy cha
LEFT JOIN 
    web_sales ws ON cha.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    cha.c_birth_year IS NOT NULL
GROUP BY 
    cha.c_first_name, cha.c_last_name, cha.age_description, p.p_promo_name, cha.c_birth_year
HAVING 
    SUM(ws.ws_sales_price) > (
        SELECT 
            AVG(ws_inner.ws_sales_price) 
        FROM 
            web_sales ws_inner
        WHERE 
            ws_inner.ws_bill_customer_sk IS NOT NULL
    )
ORDER BY 
    customer_age_group DESC, total_sales DESC;
