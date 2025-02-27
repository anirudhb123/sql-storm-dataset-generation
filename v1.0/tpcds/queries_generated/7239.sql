
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM item i
    WHERE i.i_current_price IS NOT NULL
),
aggregated_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.total_quantity) AS quantity_sold,
        SUM(sd.total_sales) AS sales_revenue
    FROM sales_data sd
    GROUP BY sd.ws_item_sk
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    id.i_item_desc,
    id.i_current_price,
    asales.sales_revenue,
    asales.quantity_sold
FROM customer_data cd
JOIN aggregated_sales asales ON cd.c_customer_sk IN (
    SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = asales.ws_item_sk
)
JOIN item_data id ON asales.ws_item_sk = id.i_item_sk
ORDER BY asales.sales_revenue DESC
LIMIT 10;
