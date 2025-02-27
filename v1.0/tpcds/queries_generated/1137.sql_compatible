
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_details AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        (SELECT COUNT(*) 
         FROM customer_address ca 
         WHERE ca.ca_address_sk = c.c_current_addr_sk) AS address_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer_details cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.order_count,
    r.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COALESCE(cd.address_count, 0) AS address_count
FROM 
    ranked_sales r
JOIN 
    customer_details cd ON r.c_customer_sk = cd.cd_demo_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC
UNION ALL
SELECT 
    'N/A' AS c_first_name,
    'N/A' AS c_last_name,
    NULL AS total_sales,
    NULL AS order_count,
    NULL AS sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COUNT(*) AS address_count
FROM 
    customer_details cd
WHERE 
    cd.cd_purchase_estimate IS NULL
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating;
