
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip)) AS full_address
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        addr.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_parts addr ON c.c_current_addr_sk = addr.ca_address_sk
),
item_stats AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COUNT(ws.ws_order_number) AS sales_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
sales_analysis AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        is.i_item_id,
        is.i_item_desc,
        is.sales_count,
        is.total_sales,
        RANK() OVER (PARTITION BY ci.cd_gender ORDER BY is.total_sales DESC) AS sales_rank
    FROM 
        customer_info ci
    JOIN 
        item_stats is ON ci.c_customer_id = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = is.i_item_id LIMIT 1)
    WHERE 
        is.sales_count > 0
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    i_item_id,
    i_item_desc,
    sales_count,
    total_sales,
    sales_rank
FROM 
    sales_analysis
WHERE 
    sales_rank <= 5
ORDER BY 
    cd_gender, total_sales DESC;
