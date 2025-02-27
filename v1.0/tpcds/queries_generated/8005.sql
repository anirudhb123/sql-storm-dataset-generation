
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
top_items AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        SUM(sd.total_quantity) AS overall_quantity,
        SUM(sd.total_sales) AS overall_sales
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_id
    ORDER BY 
        overall_sales DESC
    LIMIT 10
), 
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), 
final_analysis AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ti.i_item_id,
        ti.overall_quantity,
        ti.overall_sales,
        ca.total_spent
    FROM 
        top_items ti
    JOIN 
        customer_data ci ON ci.total_spent > 1000
)
SELECT 
    fa.c_customer_id,
    fa.cd_gender,
    fa.cd_marital_status,
    fa.i_item_id,
    fa.overall_quantity,
    fa.overall_sales,
    fa.total_spent
FROM 
    final_analysis fa
ORDER BY 
    fa.overall_sales DESC;
