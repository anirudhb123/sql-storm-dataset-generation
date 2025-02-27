
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.rank <= 10
),
CustomerPurchase AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS customer_total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
),
SalesAnalysis AS (
    SELECT 
        tp.i_item_desc,
        cp.c_customer_id,
        cp.customer_total_sales,
        cp.total_orders,
        CASE
            WHEN cp.customer_total_sales > 1000 THEN 'High Value'
            WHEN cp.customer_total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM TopItems tp
    JOIN CustomerPurchase cp ON cp.customer_total_sales > tp.total_sales
)
SELECT 
    sa.i_item_desc,
    sa.c_customer_id,
    sa.customer_value_category,
    COUNT(*) AS number_of_customers,
    AVG(sa.customer_total_sales) AS avg_sales
FROM SalesAnalysis sa
GROUP BY 
    sa.i_item_desc,
    sa.c_customer_id,
    sa.customer_value_category
HAVING 
    COUNT(*) > 1
ORDER BY 
    avg_sales DESC;
