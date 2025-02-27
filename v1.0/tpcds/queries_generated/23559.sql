
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank,
        COALESCE(ws.ws_net_paid - ws.ws_ext_discount_amt, 0) AS net_profit_after_discount,
        CAST(CONCAT('Item SK: ', ws.ws_item_sk, ', Order Number: ', ws.ws_order_number) AS varchar(100)) AS sales_info
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
)

SELECT
    c.c_customer_id,
    SUM(rs.ws_sales_price) AS total_spent,
    MAX(rs.ws_sales_price) AS max_sale,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_quantity IS NOT NULL) AS total_returns,
    CASE 
        WHEN COUNT(rs.ws_order_number) > 2 THEN 'Frequent Shopper'
        WHEN COUNT(rs.ws_order_number) BETWEEN 1 AND 2 THEN 'Occasional Shopper'
        ELSE 'New Customer'
    END AS customer_type,
    CASE 
        WHEN COUNT(rs.ws_order_number) IS NULL THEN 'No transactions'
        ELSE STRING_AGG(rs.sales_info, ', ') 
    END AS transaction_details
FROM 
    ranked_sales rs
JOIN 
    customer c ON c.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = rs.ws_item_sk 
WHERE 
    (c.c_birth_year IS NULL OR c.c_birth_year < 1990) 
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(rs.ws_sales_price) > 1000
ORDER BY 
    total_spent DESC
LIMIT 10;
