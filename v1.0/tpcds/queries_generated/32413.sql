
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_marital_status,
        ch.cd_gender,
        COALESCE(ch.dep_count, 0) + 1 AS dep_count,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON c.c_customer_sk = ch.c_customer_sk
)

SELECT 
    cha.c_customer_sk,
    cha.c_first_name,
    cha.c_last_name,
    cha.cd_gender,
    SUM(CASE 
            WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price 
            ELSE 0 
        END) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(CASE 
            WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price 
            ELSE NULL 
        END) AS max_sales,
    MIN(CASE 
            WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price 
            ELSE NULL 
        END) AS min_sales,
    ROW_NUMBER() OVER (PARTITION BY cha.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
FROM 
    CustomerHierarchy cha
LEFT JOIN 
    web_sales ws ON cha.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cha.c_customer_sk, 
    cha.c_first_name, 
    cha.c_last_name, 
    cha.cd_gender
HAVING 
    SUM(ws.ws_sales_price) > (
        SELECT 
            AVG(ws2.ws_sales_price) 
        FROM 
            web_sales ws2 
        WHERE 
            ws2.ws_ship_date_sk > (
                SELECT 
                    MIN(d.d_date_sk) 
                FROM 
                    date_dim d 
                WHERE 
                    d.d_year = 2023
            )
    )
ORDER BY 
    total_sales DESC;
