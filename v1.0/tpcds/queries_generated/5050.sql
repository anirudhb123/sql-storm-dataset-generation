
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_month = 10
    GROUP BY ws.ws_sold_date_sk
),
returns_data AS (
    SELECT 
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_month = 10
    GROUP BY wr.wr_returned_date_sk
),
daily_performance AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) AS net_revenue,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_units_sold, 0) - COALESCE(rd.total_returns, 0)) AS net_units_sold
    FROM date_dim d
    LEFT JOIN sales_data sd ON d.d_date_sk = sd.ws_sold_date_sk
    LEFT JOIN returns_data rd ON d.d_date_sk = rd.wr_returned_date_sk
    WHERE d.d_year = 2023 AND d.d_month = 10
)
SELECT 
    sales_date,
    total_sales,
    total_return_amt,
    net_revenue,
    total_orders,
    total_returns,
    net_units_sold,
    (total_sales / NULLIF(total_orders, 0)) AS avg_order_value,
    (net_revenue / NULLIF(total_orders, 0)) AS avg_net_revenue_per_order
FROM daily_performance
ORDER BY sales_date;
