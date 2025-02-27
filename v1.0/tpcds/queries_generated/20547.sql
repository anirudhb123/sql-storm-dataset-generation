
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ARRAY_LENGTH(NULLIF(cd.cd_dep_count::text, ''), 0), 0) AS dependency_score,
        SUM(CASE WHEN ws.ws_sales_price > 100 THEN 1 ELSE 0 END) AS high_value_sales_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
return_stats AS (
    SELECT 
        cr.refunded_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        COUNT(DISTINCT cr.returning_customer_sk) AS unique_returning_customers
    FROM 
        catalog_returns cr
    WHERE 
        cr_returned_date_sk IS NOT NULL
    GROUP BY 
        cr.refunded_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    sd.ws_quantity AS quantity_sold,
    sd.ws_sales_price AS last_price,
    rs.total_returns,
    (CASE 
        WHEN rs.total_returns IS NULL THEN 'No Returns'
        WHEN rs.total_returns > 0 THEN 'Returned'
        ELSE 'No Issues'
    END) AS return_status,
    COUNT(*) OVER () AS total_customers
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_id = sd.ws_item_sk::text
LEFT JOIN 
    return_stats rs ON ci.c_customer_id = rs.refunded_customer_sk::text
WHERE 
    ci.high_value_sales_count > 2
ORDER BY 
    ci.cd_gender, return_status DESC, last_price DESC
FETCH FIRST 50 ROWS ONLY;
