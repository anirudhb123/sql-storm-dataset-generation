
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_year,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
top_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit 
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
),
combined_results AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_birth_year,
        ss.total_sales,
        ss.total_quantity,
        ss.order_count,
        ti.total_quantity_sold,
        ti.total_profit
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON CAST(ss.ws_sold_date_sk AS CHAR) IN (
            SELECT 
                d.d_date_id 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = ci.cd_birth_year
        )
    JOIN 
        top_items ti ON ci.c_customer_id = (SELECT MAX(c.c_customer_id) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
)

SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.total_sales,
    cr.total_quantity,
    cr.order_count,
    cr.total_quantity_sold,
    cr.total_profit
FROM 
    combined_results cr
WHERE 
    cr.cd_gender = 'F' 
ORDER BY 
    cr.total_sales DESC 
LIMIT 100;
