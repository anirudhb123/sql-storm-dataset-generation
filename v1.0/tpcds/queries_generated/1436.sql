
WITH sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
return_summary AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
combined_sales AS (
    SELECT
        ss.ws_item_sk,
        SUM(ss.total_sales) AS combined_sales,
        SUM(ss.total_revenue) AS combined_revenue,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_loss, 0) AS total_loss,
        (SUM(ss.total_revenue) - COALESCE(rs.total_loss, 0)) AS net_revenue
    FROM sales_summary ss
    LEFT JOIN return_summary rs ON ss.ws_item_sk = rs.wr_item_sk
    GROUP BY ss.ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    c.cd_gender,
    i.i_current_price,
    cs.combined_sales,
    cs.combined_revenue,
    cs.total_returns,
    cs.net_revenue
FROM combined_sales cs
JOIN item i ON cs.ws_item_sk = i.i_item_sk
JOIN customer c ON c.c_customer_sk IN (
    SELECT c.c_customer_sk
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
)
WHERE cs.net_revenue > 0
ORDER BY cs.net_revenue DESC
FETCH FIRST 10 ROWS ONLY;
