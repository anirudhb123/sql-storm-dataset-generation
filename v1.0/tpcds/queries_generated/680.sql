
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN store s ON ws.ws_warehouse_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name
),
returns_summary AS (
    SELECT
        r.r_reason_desc,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
),
monthly_performance AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(CASE WHEN ws.ws_web_page_sk IS NOT NULL THEN 1 END) AS page_views,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(SUM(rs.total_returns), 0) AS total_returns
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN (SELECT d_year, d_month_seq, SUM(total_returns) AS total_returns
               FROM returns_summary
               JOIN date_dim on date_dim.d_date_sk = returns_summary.total_returns
               GROUP BY d_year, d_month_seq) rs ON d.d_year = rs.d_year AND d.d_month_seq = rs.d_month_seq
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    mp.d_year,
    mp.d_month_seq,
    mp.page_views,
    mp.total_sales,
    mp.total_returns,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_net_paid
FROM monthly_performance mp
JOIN sales_summary ss ON mp.d_year = ss.d_year AND mp.d_month_seq = ss.d_month_seq
WHERE ss.rank <= 5
ORDER BY mp.d_year, mp.d_month_seq;
