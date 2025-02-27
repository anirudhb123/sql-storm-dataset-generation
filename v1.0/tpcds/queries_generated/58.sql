
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450011 AND 2450688 -- Example date range
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ts.total_sales
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = (
            SELECT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_item_sk = rs.ws_item_sk 
            ORDER BY 
                ws_ext_sales_price DESC 
            LIMIT 1
        )
    JOIN 
        (SELECT 
            ws_item_sk, 
            SUM(ws_sales_price) AS total_sales 
         FROM 
            web_sales 
         GROUP BY 
            ws_item_sk) ts ON ts.ws_item_sk = rs.ws_item_sk
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(tc.total_sales, 0) AS sales_amount,
    CASE 
        WHEN tc.cd_purchase_estimate < 1000 THEN 'Low'
        WHEN tc.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_category
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c_current_addr_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk = tc.c_customer_sk
    )
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    sales_amount DESC, 
    tc.cd_marital_status ASC;
