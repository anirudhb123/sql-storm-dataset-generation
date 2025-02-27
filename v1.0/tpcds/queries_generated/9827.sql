
WITH sales_data AS (
    SELECT
        ws.web_site_id,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        AVG(ws_ext_discount_amt) AS avg_discount,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.web_site_sk = w.web_site_sk
    JOIN
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND
        d.d_moy IN (11, 12) -- October and November
    GROUP BY
        ws.web_site_id
),
top_websites AS (
    SELECT
        web_site_id,
        total_profit,
        total_orders,
        avg_sales_price,
        avg_discount
    FROM
        sales_data
    WHERE
        profit_rank <= 10
)
SELECT
    t.web_site_id,
    t.total_profit,
    t.total_orders,
    t.avg_sales_price,
    t.avg_discount,
    COALESCE(SUM(ws.net_paid_inc_tax), 0) AS total_revenue,
    COUNT(DISTINCT r.returning_customer_sk) AS total_returns,
    AVG(CASE WHEN r.return_quantity > 0 THEN r.return_amt ELSE NULL END) AS avg_return_amount
FROM
    top_websites t
LEFT JOIN
    web_sales ws ON t.web_site_id = ws.web_site_id
LEFT JOIN
    web_returns r ON ws.order_number = r.order_number
GROUP BY
    t.web_site_id, t.total_profit, t.total_orders, t.avg_sales_price, t.avg_discount
ORDER BY
    t.total_profit DESC;
