
WITH sales_summary AS (
    SELECT
        d.d_year AS sales_year,
        sm.sm_ship_mode_id AS shipping_mode,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        d.d_year,
        sm.sm_ship_mode_id
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
return_summary AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM
        store_returns
    GROUP BY
        sr_returned_date_sk
),
profit_analysis AS (
    SELECT
        ss.sales_year,
        ss.shipping_mode,
        ss.total_sales,
        ss.total_orders,
        ss.avg_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        (ss.total_sales - COALESCE(rs.total_return_value, 0)) AS net_sales
    FROM
        sales_summary ss
    LEFT JOIN
        return_summary rs ON ss.sales_year = EXTRACT(YEAR FROM rs.sr_returned_date_sk)
)
SELECT
    pa.sales_year,
    pa.shipping_mode,
    pa.total_sales,
    pa.total_orders,
    pa.avg_net_profit,
    pa.total_returns,
    pa.total_return_value,
    pa.net_sales,
    COUNT(DISTINCT ci.c_customer_sk) AS active_customers,
    AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate
FROM
    profit_analysis pa
LEFT JOIN
    customer_info ci ON ci.hd_income_band_sk IS NOT NULL
WHERE
    pa.total_sales > 0
GROUP BY
    pa.sales_year,
    pa.shipping_mode,
    pa.total_sales,
    pa.total_orders,
    pa.avg_net_profit,
    pa.total_returns,
    pa.total_return_value,
    pa.net_sales
ORDER BY
    pa.sales_year,
    pa.shipping_mode;
