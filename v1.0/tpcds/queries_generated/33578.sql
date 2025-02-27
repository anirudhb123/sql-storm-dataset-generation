
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY 
        ws_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        i.i_item_id,
        i.i_item_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    WHERE 
        rank <= 10
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(NULLIF(ti.total_sales, 0), 0) AS non_zero_sales,
    COUNT(DISTINCT cd.i_item_id) OVER () AS unique_items_count
FROM 
    customer_details cd
JOIN 
    top_items ti ON cd.ws_item_sk = ti.ws_item_sk
ORDER BY 
    ti.total_sales DESC, 
    cd.c_last_name ASC;
