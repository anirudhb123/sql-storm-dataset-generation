
WITH sales_summary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
),
store_summary AS (
    SELECT
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_store_orders,
        SUM(ss_net_profit) AS total_store_net_profit
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
return_summary AS (
    SELECT
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_store_sk
)
SELECT
    w.warehouse_id,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit_sold,
    COALESCE(s.total_store_orders, 0) AS total_orders_from_store,
    COALESCE(s.total_store_net_profit, 0) AS total_net_profit_from_store,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN COALESCE(ss.total_net_profit, 0) > 0 THEN 'Profitable'
        WHEN COALESCE(r.total_returned_amount, 0) > COALESCE(ss.total_net_profit, 0) THEN 'Loss'
        ELSE 'Neutral'
    END AS profit_status
FROM
    warehouse w
LEFT JOIN
    sales_summary ss ON w.warehouse_sk = ss.ws_sold_date_sk
LEFT JOIN
    store_summary s ON w.warehouse_sk = s.ss_store_sk
LEFT JOIN
    return_summary r ON w.warehouse_sk = r.sr_store_sk
WHERE
    w.warehouse_sq_ft > 1000
    AND COALESCE(ss.total_net_profit, 0) > 1000
ORDER BY
    total_net_profit_sold DESC;
