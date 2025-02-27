
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as rn
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk

    UNION ALL

    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.total_quantity + COALESCE((SELECT SUM(ws_quantity) FROM web_sales WHERE ws_item_sk = sd.ws_item_sk AND ws_order_number < sd.ws_order_number), 0),
        sd.total_sales + COALESCE((SELECT SUM(ws_sales_price) FROM web_sales WHERE ws_item_sk = sd.ws_item_sk AND ws_order_number < sd.ws_order_number), 0),
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.ws_order_number) AS rn
    FROM SalesData sd
    WHERE sd.rn < (SELECT COUNT(*) FROM web_sales WHERE ws_item_sk = sd.ws_item_sk)
)

SELECT 
    c.c_customer_id,
    SUM(sd.total_quantity) AS total_quantity_purchased,
    SUM(sd.total_sales) AS total_sales_amount,
    cd.cd_gender,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores_purchased_from
FROM SalesData sd
JOIN web_sales ws ON sd.ws_order_number = ws.ws_order_number AND sd.ws_item_sk = ws.ws_item_sk
JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN store s ON s.s_store_sk = ws.ws_ship_addr_sk
WHERE 
    ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
    AND ws_sold_date_sk < (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND sd.total_sales > 1000
GROUP BY 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status
HAVING 
    SUM(sd.total_sales) > 5000
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
