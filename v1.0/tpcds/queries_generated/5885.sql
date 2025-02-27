
WITH aggregated_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        d.d_date AS purchase_date,
        d.d_month_seq,
        d.d_year
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MIN(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
), 
final_report AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ag.total_sales,
        ag.total_orders
    FROM 
        customer_info ci
    JOIN 
        aggregated_sales ag ON ci.c_customer_sk = ag.ws_item_sk
    JOIN 
        customer c ON ci.c_customer_sk = c.c_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.total_sales,
    f.total_orders
FROM 
    final_report f
WHERE 
    f.total_sales > (SELECT AVG(total_sales) FROM aggregated_sales)
ORDER BY 
    f.total_sales DESC
LIMIT 100;
