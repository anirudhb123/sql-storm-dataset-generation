
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rnk,
        COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), NULL) AS effective_discount,
        MAX(ws.ws_sales_price * (1 - (COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), 0) / NULLIF(ws.ws_sales_price, 0)))) OVER (PARTITION BY ws.ws_order_number) AS max_effective_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000 AND
        c.c_current_cdemo_sk IS NOT NULL
),
total_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
final_report AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.effective_discount,
        rs.max_effective_price,
        COALESCE(tr.total_returned, 0) AS refunded_quantity,
        CASE 
            WHEN rs.ws_sales_price > 100 THEN 'High Value'
            WHEN rs.ws_sales_price BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS price_category
    FROM 
        ranked_sales rs
    LEFT JOIN 
        total_returns tr ON rs.ws_item_sk = tr.sr_item_sk
)
SELECT 
    f.ws_order_number,
    COUNT(DISTINCT f.ws_item_sk) AS distinct_items,
    SUM(f.effective_discount) AS total_discount_given,
    AVG(f.max_effective_price) AS average_max_effective_price,
    STRING_AGG(CONCAT('Item: ', f.ws_item_sk, ', Price Category: ', f.price_category) ORDER BY f.ws_item_sk) AS item_details
FROM 
    final_report f
WHERE 
    f.refunded_quantity = 0
GROUP BY 
    f.ws_order_number
HAVING 
    AVG(f.max_effective_price) > (SELECT AVG(max_effective_price) FROM final_report)
ORDER BY 
    distinct_items DESC, total_discount_given DESC;
