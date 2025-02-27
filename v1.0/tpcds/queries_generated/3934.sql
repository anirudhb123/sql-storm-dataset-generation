
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        COUNT(rs.ws_item_sk) AS item_count,
        SUM(rs.ws_net_paid) AS total_spent
    FROM customer c
    JOIN RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
    HAVING SUM(rs.ws_net_paid) > 1000
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY w.w_warehouse_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        ct.total_spent,
        wi.total_revenue,
        CASE 
            WHEN ct.total_spent > 2000 THEN 'High Value'
            WHEN ct.total_spent BETWEEN 1000 AND 2000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_category
    FROM TopCustomers ct
    LEFT JOIN WarehouseInfo wi ON ct.total_spent > wi.total_revenue
)
SELECT 
    cp.c_customer_sk,
    cp.total_spent,
    cp.total_revenue,
    cp.customer_category,
    COALESCE(wi.total_items_sold, 0) AS total_items_sold
FROM CustomerPurchases cp
LEFT JOIN WarehouseInfo wi ON cp.c_customer_sk = wi.w_warehouse_sk
ORDER BY cp.customer_category, cp.total_spent DESC;
