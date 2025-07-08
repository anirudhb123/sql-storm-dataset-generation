
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 2700
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        total_discount,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SalesSummary
    WHERE 
        total_quantity > 100
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_discount,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN 
    customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk LIMIT 1)
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_sales DESC;
