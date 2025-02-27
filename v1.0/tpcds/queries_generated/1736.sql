
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 365 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_orders,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ti.ws_item_sk,
    i.i_item_id,
    i.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    ti.total_orders,
    COALESCE(NULLIF(d.d_average_discount, 0), 'No Discount') AS average_discount
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    (SELECT 
        cs_item_sk,
        AVG(cs_ext_discount_amt) AS d_average_discount
     FROM 
        catalog_sales
     GROUP BY 
        cs_item_sk) d ON ti.ws_item_sk = d.cs_item_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
