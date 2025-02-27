
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_sale_date,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        SUM(ws_sales_price) AS total_spent
    FROM web_sales 
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    HAVING SUM(ws_sales_price) > 1000
),
address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
return_stats AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_number) AS total_returns,
        SUM(wr_return_quantity) AS total_returned_quantity
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.total_sales,
    cs.total_orders,
    cs.last_sale_date,
    hc.total_spent,
    ai.full_address,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity
FROM sales_summary cs
LEFT JOIN high_value_customers hc ON cs.ws_item_sk = hc.c_customer_sk
LEFT JOIN address_info ai ON hc.c_current_addr_sk = ai.ca_address_sk
LEFT JOIN return_stats rs ON cs.ws_item_sk = rs.wr_item_sk
WHERE cs.sales_rank <= 10
ORDER BY cs.total_sales DESC, total_spent DESC;
