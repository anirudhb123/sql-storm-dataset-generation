
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS return_count,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_sold_quantity,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS total_sales_amount,
        SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_return_quantity ELSE 0 END) AS total_return_quantity,
        SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_return_amt ELSE 0 END) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_sk
),
return_analysis AS (
    SELECT 
        cs.c_customer_sk,
        is.i_item_sk,
        cs.return_count,
        cs.total_return_quantity,
        cs.total_return_amount,
        is.total_sold_quantity,
        is.total_sales_amount,
        is.total_return_quantity AS item_total_return_quantity,
        is.total_return_amount AS item_total_return_amount
    FROM 
        customer_summary cs
    JOIN 
        item_summary is ON cs.c_customer_sk = is.i_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    r.total_sold_quantity,
    r.total_sales_amount,
    r.total_return_quantity,
    r.total_return_amount,
    r.item_total_return_quantity,
    r.item_total_return_amount
FROM 
    return_analysis r
JOIN 
    customer c ON r.c_customer_sk = c.c_customer_sk
WHERE 
    r.total_sold_quantity > 0 
    AND r.total_return_quantity > 0
ORDER BY 
    r.total_return_amount DESC
LIMIT 100;
