
WITH sold_items AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), top_items AS (
    SELECT 
        si.ws_item_sk, 
        i.i_item_id, 
        i.i_item_desc, 
        si.total_quantity, 
        si.total_sales
    FROM 
        sold_items si
    JOIN 
        item i ON si.ws_item_sk = i.i_item_sk
    WHERE 
        si.rank <= 10
), customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.net_paid_inc_tax), 0) AS total_purchase
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_quantity,
    tp.total_sales,
    cp.total_purchase,
    CASE 
        WHEN cp.total_purchase > 500 THEN 'High Value'
        WHEN cp.total_purchase BETWEEN 200 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    customer_purchases cp
JOIN 
    top_items tp ON cp.total_purchase > 0
ORDER BY 
    cp.total_purchase DESC, tp.total_sales DESC
LIMIT 50;
