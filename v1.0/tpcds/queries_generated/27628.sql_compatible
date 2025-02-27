
WITH AggregatedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM web_sales ws
    JOIN catalog_page cp ON ws.ws_item_sk = cp.cp_catalog_page_sk
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT
        a.ws_item_sk,
        a.total_quantity_sold,
        a.total_sales_amount,
        ROW_NUMBER() OVER (ORDER BY a.total_sales_amount DESC) AS sales_rank
    FROM AggregatedSales a
    WHERE a.total_quantity_sold > 100
),
HighSalesCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM TopItems WHERE sales_rank <= 10)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    hsc.c_customer_sk,
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(cp.cp_catalog_page_id, ' ', cp.cp_description)) AS purchased_items
FROM HighSalesCustomers hsc
JOIN web_sales ws ON hsc.c_customer_sk = ws.ws_bill_customer_sk
JOIN catalog_page cp ON ws.ws_item_sk = cp.cp_catalog_page_sk
GROUP BY hsc.c_customer_sk, hsc.c_first_name, hsc.c_last_name
ORDER BY hsc.total_spent DESC;
