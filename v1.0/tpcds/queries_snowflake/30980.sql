WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_quarter_seq
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq, d.d_quarter_seq
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk - 1
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        MAX(cd.cd_dep_count) AS dependents,
        MAX(cd.cd_marital_status) AS marital_status
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
WarehouseInventory AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.orders_count,
        wh.total_inventory,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerStats cs
    JOIN WarehouseInventory wh ON cs.c_customer_sk = wh.w_warehouse_sk
    WHERE cs.total_sales IS NOT NULL
),
SalesByMonth AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY sale_month
),
FinalStats AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_sales,
        tc.orders_count,
        sbm.sale_month,
        COALESCE(sbm.monthly_sales, 0) AS monthly_sales
    FROM TopCustomers tc
    LEFT JOIN SalesByMonth sbm ON EXTRACT(MONTH FROM cast('2002-10-01' as date)) = sbm.sale_month
    WHERE tc.sales_rank <= 10
)
SELECT 
    f.c_customer_sk,
    f.total_sales,
    f.orders_count,
    f.monthly_sales,
    CASE 
        WHEN f.monthly_sales > 1000 THEN 'High Value Customer'
        WHEN f.monthly_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM FinalStats f
LEFT JOIN customer_demographics cd ON f.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_dep_count IS NOT NULL
ORDER BY f.total_sales DESC;