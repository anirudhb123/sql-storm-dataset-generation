
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
aggregated_sales AS (
    SELECT 
        sd.ws_item_sk,
        id.i_item_desc,
        id.i_brand,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_sales) AS total_sales_amount,
        SUM(sd.total_discount) AS total_discount_amount,
        SUM(sd.total_profit) AS total_profit_amount
    FROM 
        sales_data sd
    JOIN 
        item_data id ON sd.ws_item_sk = id.i_item_sk
    GROUP BY 
        sd.ws_item_sk, id.i_item_desc, id.i_brand
),
final_report AS (
    SELECT 
        ad.ws_item_sk,
        ad.i_item_desc,
        ad.i_brand,
        ad.total_quantity_sold,
        ad.total_sales_amount,
        ad.total_discount_amount,
        ad.total_profit_amount,
        COUNT(DISTINCT cd.c_customer_id) AS unique_customers
    FROM 
        aggregated_sales ad
    LEFT JOIN 
        customer_data cd ON cd.c_customer_sk IN (
            SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ad.ws_item_sk
        )
    GROUP BY 
        ad.ws_item_sk, ad.i_item_desc, ad.i_brand, ad.total_quantity_sold, ad.total_sales_amount, ad.total_discount_amount, ad.total_profit_amount
)
SELECT 
    f.ws_item_sk,
    f.i_item_desc,
    f.i_brand,
    f.total_quantity_sold,
    f.total_sales_amount,
    f.total_discount_amount,
    f.total_profit_amount,
    f.unique_customers
FROM 
    final_report f
ORDER BY 
    f.total_sales_amount DESC 
LIMIT 10;
