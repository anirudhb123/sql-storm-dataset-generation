
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighestSales AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
TargetDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_credit_rating = 'Excellent'
)
SELECT 
    h.c_customer_id,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    h.order_count,
    td.cd_gender,
    td.cd_marital_status,
    td.cd_education_status
FROM 
    HighestSales h
LEFT JOIN 
    TargetDemographics td ON h.c_customer_id = (
        SELECT 
            c.c_customer_id 
        FROM 
            customer c 
        WHERE 
            c.c_current_cdemo_sk = td.cd_demo_sk
        LIMIT 1
    )
WHERE 
    h.sales_rank <= 10
UNION ALL
SELECT 
    NULL AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    NULL AS total_sales,
    NULL AS order_count,
    td.cd_gender,
    td.cd_marital_status,
    td.cd_education_status
FROM 
    TargetDemographics td
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM HighestSales h 
        WHERE h.c_customer_id = (
            SELECT c.c_customer_id 
            FROM customer c 
            WHERE c.c_current_cdemo_sk = td.cd_demo_sk
            LIMIT 1
        )
    )
ORDER BY 
    total_sales DESC NULLS LAST, 
    order_count ASC;
