
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_sales_price,
        ws_quantity,
        ws_sales_price * ws_quantity AS total_sales,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    UNION ALL
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sold_date_sk,
        cs_sales_price,
        cs_quantity,
        cs_sales_price * cs_quantity AS total_sales,
        level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_data sd ON cs.cs_order_number = sd.ws_order_number AND cs.cs_item_sk = sd.ws_item_sk
    WHERE 
        level < 3
),
customer_returns AS (
    SELECT 
        sr_customer_sk AS customer_id,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY 
        sr_customer_sk
),
final_result AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        SUM(sd.total_sales) AS total_sales,
        COALESCE(cr.total_returned, 0) AS total_returns,
        SUM(sd.total_sales) - COALESCE(cr.total_returned, 0) AS net_sales
    FROM 
        sales_data sd
    LEFT JOIN 
        customer_returns cr ON cr.customer_id = sd.ws_order_number
    GROUP BY 
        sd.ws_order_number, sd.ws_item_sk
    HAVING 
        net_sales > 0
)
SELECT 
    ws.ws_order_number,
    it.i_item_id,
    it.i_item_desc,
    fr.total_sales,
    fr.total_returns,
    fr.net_sales
FROM 
    final_result fr
JOIN 
    item it ON fr.ws_item_sk = it.i_item_sk
JOIN 
    web_sales ws ON fr.ws_order_number = ws.ws_order_number
ORDER BY 
    fr.net_sales DESC
LIMIT 100;
