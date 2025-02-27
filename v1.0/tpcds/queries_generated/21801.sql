
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS customer_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), top_customers AS (
    SELECT 
        ss.ws_bill_customer_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        cd_gender,
        cd_marital_status
    FROM sales_summary ss
    LEFT JOIN customer c ON ss.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ss.customer_rank <= 10
), detailed_returns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
), return_summary AS (
    SELECT 
        t_customer.ws_bill_customer_sk AS customer_sk,
        COALESCE(d_total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(total_returns, 0) AS total_returns,
        total_quantity,
        total_sales,
        order_count,
        cd_gender,
        cd_marital_status
    FROM top_customers t_customer
    LEFT JOIN detailed_returns d_customer ON t_customer.ws_bill_customer_sk = d_customer.returning_customer_sk
    LEFT JOIN customer_demographics cd ON t_customer.ws_bill_customer_sk = cd.cd_demo_sk
)
SELECT 
    r.customer_sk,
    r.total_quantity,
    r.total_sales,
    r.total_returned_quantity,
    r.order_count,
    r.total_returns,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Value'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    CONCAT(cd_gender, '-', cd_marital_status) AS demographic_segment
FROM return_summary r
JOIN customer_demographics cd ON r.customer_sk = cd.cd_demo_sk
WHERE (r.total_sales IS NOT NULL AND r.total_sales > 0)
   OR (r.total_returned_quantity IS NOT NULL AND r.total_returned_quantity > 0)
ORDER BY r.total_sales DESC, r.total_returned_quantity ASC
FETCH FIRST 20 ROWS ONLY;
