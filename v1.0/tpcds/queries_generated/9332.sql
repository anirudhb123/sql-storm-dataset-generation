
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_sale_date,
        MIN(d.d_date) AS first_sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        SUM(ss.total_sales) AS total_customer_sales,
        COUNT(DISTINCT ss.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        web_sales ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    JOIN 
        sales_summary s ON ss.ws_item_sk = s.ws_item_sk
    GROUP BY 
        c.c_customer_sk, d.cd_gender, d.cd_marital_status, d.cd_education_status
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(s.total_sales) AS total_item_sales,
        COUNT(DISTINCT ss.ws_order_number) AS order_count
    FROM 
        sales_summary s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_customer_sales,
    cs.unique_items_purchased,
    is.item_total_sales,
    is.order_count AS item_order_count,
    ss.first_sale_date,
    ss.last_sale_date
FROM 
    customer_summary cs
JOIN 
    item_summary is ON is.total_item_sales = (SELECT MAX(total_sales) FROM item_summary)
JOIN 
    sales_summary ss ON ss.ws_item_sk = is.i_item_sk
WHERE 
    cs.total_customer_sales > 1000
ORDER BY 
    cs.total_customer_sales DESC;
