
WITH RECURSIVE PreviousYears AS (
    SELECT d_date_sk, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_year <= 2022
    UNION ALL
    SELECT d.d_date_sk, d.d_year, d.d_month_seq, d.d_week_seq
    FROM date_dim d
    INNER JOIN PreviousYears p ON d.d_year = p.d_year + 1
), SalesData AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN PreviousYears py ON ws.ws_sold_date_sk = py.d_date_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_gender = 'F'
      AND ws.ws_sales_price > 50
      AND (cd.cd_credit_rating IS NOT NULL AND cd.cd_credit_rating <> 'Poor')
    GROUP BY c.c_customer_sk
),
TopSales AS (
    SELECT 
        customer_sk,
        total_orders,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS rank
    FROM SalesData
)
SELECT 
    c.c_customer_id,
    sa.total_orders,
    sa.total_profit,
    sa.avg_quantity,
    CASE 
        WHEN sa.total_orders > 10 THEN 'High Activity'
        WHEN sa.total_orders BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_status,
    w.w_warehouse_name,
    CASE 
        WHEN w.w_gmt_offset IS NULL THEN 'Offset Not Available'
        ELSE CAST(w.w_gmt_offset AS VARCHAR)
    END AS gmt_offset
FROM TopSales ts
JOIN customer c ON ts.customer_sk = c.c_customer_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ts.rank <= 100
ORDER BY ts.total_profit DESC
