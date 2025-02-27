
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesWithReturns AS (
    SELECT 
        w.ws_bill_customer_sk,
        COALESCE(c.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(c.total_return_amount, 0) AS total_return_amount,
        w.total_sales,
        w.total_orders
    FROM WebSales w
    LEFT JOIN CustomerReturns c ON w.ws_bill_customer_sk = c.cr_returning_customer_sk
),
RankedSales AS (
    SELECT 
        swr.ws_bill_customer_sk,
        swr.total_sales,
        swr.total_orders,
        swr.total_returned_quantity,
        swr.total_return_amount,
        RANK() OVER (ORDER BY swr.total_sales DESC) AS sales_rank
    FROM SalesWithReturns swr
)

SELECT 
    r.customer_address,
    r.total_sales,
    r.total_orders,
    r.total_returned_quantity,
    r.total_return_amount,
    COALESCE(c.ca_city, 'Unknown') AS city,
    CASE
        WHEN r.sales_rank <= 10 THEN 'Top Buyer'
        ELSE 'Regular Buyer'
    END AS buyer_category
FROM RankedSales r
LEFT JOIN customer c ON r.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE r.total_sales > 500
ORDER BY r.total_sales DESC;
