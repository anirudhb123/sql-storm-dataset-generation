
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amt) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_profit) AS average_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
StoreSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_sales_price) AS total_store_sales,
        COUNT(ss_ticket_number) AS store_order_count
    FROM store_sales
    GROUP BY ss_customer_sk
),
CombinedSales AS (
    SELECT 
        customer.c_customer_sk,
        COALESCE(cs.total_returned, 0) AS total_returned,
        COALESCE(cs.total_return_amount, 0) AS total_return_amount,
        COALESCE(cs.total_return_tax, 0) AS total_return_tax,
        COALESCE(ws.total_orders, 0) AS total_web_orders,
        COALESCE(ws.total_sales, 0) AS total_web_sales,
        COALESCE(ws.average_profit, 0) AS average_web_profit,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.store_order_count, 0) AS total_store_orders
    FROM customer AS customer 
    LEFT JOIN CustomerReturns AS cs ON customer.c_customer_sk = cs.cr_returning_customer_sk
    LEFT JOIN WebSalesSummary AS ws ON customer.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN StoreSales AS ss ON customer.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    combined.total_returned,
    combined.total_return_amount,
    combined.total_return_tax,
    combined.total_web_orders,
    combined.total_web_sales,
    combined.average_web_profit,
    combined.total_store_sales,
    combined.total_store_orders,
    CASE 
        WHEN combined.total_web_sales > 100000 THEN 'High Value'
        WHEN combined.total_store_sales > 100000 THEN 'High Value'
        ELSE 'Other'
    END AS customer_value_category
FROM CombinedSales AS combined
JOIN customer AS c ON combined.c_customer_sk = c.c_customer_sk
WHERE (combined.total_web_sales + combined.total_store_sales) > 5000
ORDER BY combined.total_returned DESC, combined.total_web_sales DESC;
