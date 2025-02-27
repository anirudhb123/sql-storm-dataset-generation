
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent,
        AVG(COALESCE(cd.cd_dep_count, 0)) AS avg_dependents
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
DailyPerformance AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_sales) AS total_sales_revenue,
        SUM(sd.total_profit) AS total_profit
    FROM date_dim d
    LEFT JOIN SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    GROUP BY d.d_date
    ORDER BY d.d_date DESC
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_dependents,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSummary cs
    WHERE cs.total_spent > 1000
)
SELECT 
    dp.sales_date,
    dp.total_quantity_sold,
    dp.total_sales_revenue,
    dp.total_profit,
    tc.rank AS customer_rank,
    tc.total_orders,
    tc.total_spent,
    tc.avg_dependents
FROM DailyPerformance dp
LEFT JOIN TopCustomers tc ON dp.total_sales_revenue > 10000
ORDER BY dp.sales_date DESC, tc.rank ASC
LIMIT 50;
