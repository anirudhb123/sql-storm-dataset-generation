
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold_quantity,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
),
high_value_items AS (
    SELECT 
        item_summary.i_item_sk,
        item_summary.i_product_name,
        item_summary.total_sold_quantity,
        item_summary.total_sales_value,
        item_summary.order_count,
        RANK() OVER (ORDER BY total_sales_value DESC) AS value_rank
    FROM 
        item_summary
    WHERE 
        total_sales_value > 1000
),
customer_returns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_return_order_number) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hv.i_product_name,
    hv.total_sold_quantity,
    hv.total_sales_value,
    cr.return_count,
    cr.total_return_amount
FROM 
    customer c
LEFT JOIN 
    customer_returns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
JOIN 
    high_value_items hv ON hv.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    cr.return_count > 5
ORDER BY 
    value_rank, cr.total_return_amount DESC;
