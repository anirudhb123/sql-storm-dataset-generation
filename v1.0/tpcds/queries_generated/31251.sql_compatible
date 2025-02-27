
WITH RECURSIVE sales_volume AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
most_active_customers AS (
    SELECT 
        cv.customer_sk,
        cv.total_sales, 
        cv.order_count,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM sales_volume cv
    JOIN customer c ON cv.customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cv.order_count > 5
), 
return_summary AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amount) AS total_returned,
        COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
), 
final_report AS (
    SELECT 
        mac.customer_sk,
        mac.total_sales,
        mac.order_count,
        mac.c_first_name,
        mac.c_last_name,
        mac.ca_city,
        mac.ca_state,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.return_count, 0) AS return_count,
        (mac.total_sales - COALESCE(rs.total_returned, 0)) AS net_sales
    FROM most_active_customers mac
    LEFT JOIN return_summary rs ON mac.customer_sk = rs.sr_returning_customer_sk
)
SELECT 
    customer_sk,
    c_first_name,
    c_last_name,
    ca_city,
    ca_state,
    total_sales,
    order_count,
    total_returned,
    return_count,
    net_sales
FROM final_report
ORDER BY net_sales DESC
LIMIT 10;
