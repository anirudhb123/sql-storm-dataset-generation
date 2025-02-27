
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        i.i_category AS item_category,
        cd.cd_gender AS customer_gender,
        d.d_year AS sales_year,
        s.s_store_name AS store_name
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_shipping_store_sk = s.s_store_sk
    WHERE 
        d.d_year >= 2021 AND d.d_year <= 2023
    GROUP BY 
        ws.ws_item_sk, i.i_category, cd.cd_gender, d.d_year, s.s_store_name
)
SELECT 
    sales_year,
    item_category,
    customer_gender,
    SUM(total_quantity_sold) AS overall_quantity_sold,
    SUM(total_sales) AS overall_sales,
    COUNT(DISTINCT store_name) AS distinct_stores
FROM 
    SalesData
GROUP BY 
    sales_year, item_category, customer_gender
ORDER BY 
    sales_year DESC, overall_sales DESC;
