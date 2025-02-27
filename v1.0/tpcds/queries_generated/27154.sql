
WITH ranked_item AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        LENGTH(i.i_item_desc) AS description_length,
        REPLACE(UPPER(i.i_item_desc), ' ', '') AS trimmed_upper_desc,
        ROW_NUMBER() OVER (ORDER BY LENGTH(i.i_item_desc) DESC) AS rank_desc
    FROM 
        item i
    WHERE 
        i.i_item_desc IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS full_name_length
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ri.i_item_id,
    ri.i_item_desc,
    ri.description_length,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_name_length,
    ss.total_quantity_sold,
    ss.total_sales_amount
FROM 
    ranked_item ri
JOIN 
    sales_summary ss ON ri.i_item_sk = ss.ws_item_sk
JOIN 
    customer_info ci ON ci.c_customer_sk IN (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk = ri.i_item_sk
    )
WHERE 
    ri.rank_desc <= 10
ORDER BY 
    ri.description_length DESC, 
    ss.total_sales_amount DESC;
