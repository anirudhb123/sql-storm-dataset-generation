
WITH SalesSummary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales AS ws
    JOIN
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY
        w.w_warehouse_id
),
CustomerSummary AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM
        customer AS c
    JOIN
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ca.ca_state IS NOT NULL
    GROUP BY
        ca.ca_state
),
SalesReturns AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM
        store_returns AS sr
    GROUP BY
        sr.sr_store_sk
),
FinalSummary AS (
    SELECT
        cs.ca_state,
        SUM(ss.total_net_profit) AS warehouse_net_profit,
        SUM(cs.total_customers) AS total_customers,
        SUM(cs.total_purchase_estimate) AS total_purchase_estimate,
        COALESCE(SUM(sr.total_return_amount), 0) AS total_return_amount,
        COUNT(DISTINCT ss.total_orders) AS total_orders
    FROM
        CustomerSummary AS cs
    FULL OUTER JOIN SalesSummary AS ss ON cs.ca_state = ss.w_warehouse_id
    LEFT JOIN SalesReturns AS sr ON ss.w_warehouse_id = sr.sr_store_sk
    GROUP BY
        cs.ca_state
)
SELECT
    fs.ca_state,
    fs.warehouse_net_profit,
    fs.total_customers,
    fs.total_purchase_estimate,
    fs.total_return_amount,
    fs.total_orders,
    RANK() OVER (ORDER BY fs.warehouse_net_profit DESC) AS profit_rank
FROM
    FinalSummary AS fs
WHERE
    fs.total_orders > 5
ORDER BY
    fs.warehouse_net_profit DESC;
