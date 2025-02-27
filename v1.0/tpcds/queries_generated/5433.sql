
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        ws.ws_sales_price > 50
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, cd.cd_gender, cd.cd_marital_status
),
top_sales AS (
    SELECT 
        item_sk,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY total_sales DESC) AS rn
    FROM 
        sales_data
)
SELECT 
    ts.item_sk,
    ts.total_sales,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    top_sales ts
JOIN 
    customer_demographics cd ON ts.cd_gender = cd.cd_gender AND ts.cd_marital_status = cd.cd_marital_status
WHERE 
    ts.rn <= 5
ORDER BY 
    cd.cd_gender, cd.cd_marital_status, ts.total_sales DESC;
