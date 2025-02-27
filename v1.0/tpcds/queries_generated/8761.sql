
WITH SalesSummary AS (
    SELECT 
        w.warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_net_profit) AS max_net_profit,
        MIN(ws_net_profit) AS min_net_profit,
        d.d_year
    FROM
        store_sales AS ss
    JOIN
        warehouse AS w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN
        web_sales AS ws ON ss.ss_item_sk = ws.ws_item_sk
    JOIN
        date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        w.warehouse_id, d.d_year
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM
        customer_demographics AS cd
    JOIN
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_gender
),
ReturnStats AS (
    SELECT 
        sr_reason_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM
        store_returns
    GROUP BY
        sr_reason_sk
)
SELECT 
    ss.warehouse_id,
    ss.total_sales,
    ss.total_orders,
    ss.avg_sales_price,
    ss.max_net_profit,
    ss.min_net_profit,
    d.cd_gender,
    d.avg_purchase_estimate,
    d.total_customers,
    rs.return_count,
    rs.total_return_value
FROM
    SalesSummary AS ss
LEFT JOIN
    Demographics AS d ON d.avg_purchase_estimate > 100
LEFT JOIN
    ReturnStats AS rs ON ss.warehouse_id = CAST(rs.sr_reason_sk AS INTEGER) % 10
ORDER BY
    ss.total_sales DESC, d.total_customers DESC;
