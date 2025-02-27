
WITH ranked_sales AS (
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_sales_price, 
        cs_ext_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS rnk
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND cs_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        i.i_item_id, 
        i.i_product_name, 
        SUM(ranked_sales.cs_sales_price) AS total_sales
    FROM 
        ranked_sales
    JOIN 
        item i ON ranked_sales.cs_item_sk = i.i_item_sk
    WHERE 
        ranked_sales.rnk <= 10
    GROUP BY 
        i.i_item_id, 
        i.i_product_name
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final_report AS (
    SELECT 
        customer_info.c_customer_id, 
        customer_info.c_first_name, 
        customer_info.c_last_name, 
        customer_info.cd_gender,
        customer_info.cd_marital_status, 
        top_sales.i_item_id, 
        top_sales.i_product_name, 
        top_sales.total_sales
    FROM 
        top_sales
    JOIN 
        customer_info ON customer_info.c_customer_id IN (
            SELECT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        )
)
SELECT 
    final_report.c_customer_id,
    final_report.c_first_name,
    final_report.c_last_name,
    final_report.cd_gender,
    final_report.cd_marital_status,
    final_report.i_item_id,
    final_report.i_product_name,
    final_report.total_sales
FROM 
    final_report
ORDER BY 
    final_report.total_sales DESC;
