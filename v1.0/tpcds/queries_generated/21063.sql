
WITH RECURSIVE season_sales AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE dd.d_year IS NOT NULL
    GROUP BY d_year
),
customer_return_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_orders,
        SUM(COALESCE(sr_net_loss, 0)) AS net_loss
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cd.cd_demo_sk,
        c.c_customer_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY cd.cd_demo_sk, c.c_customer_sk
    HAVING MAX(cd.cd_purchase_estimate) > 1000
),
returns_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.total_returns,
        ci.return_orders,
        ci.net_loss,
        hvc.max_purchase_estimate
    FROM customer_return_info ci
    JOIN customer c ON ci.c_customer_sk = c.c_customer_sk
    LEFT JOIN high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
),
warehouse_activity AS (
    SELECT 
        w.w_warehouse_name,
        SUM(CASE WHEN inv_quantity_on_hand IS NULL THEN 0 ELSE inv_quantity_on_hand END) AS total_inventory,
        COUNT(i.i_item_sk) AS inventory_items
    FROM warehouse w
    LEFT JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN date_dim dd ON dd.d_date_sk = i.inv_date_sk
    WHERE dd.d_year BETWEEN 2021 AND 2023
    GROUP BY w.w_warehouse_name
)
SELECT 
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_returns,
    rs.return_orders,
    rs.net_loss,
    COALESCE(ws.total_sales, 0) AS yearly_sales,
    wa.total_inventory,
    wa.inventory_items,
    CASE 
        WHEN rs.total_returns > 0 THEN 'Returns'
        ELSE 'No Returns'
    END AS return_status
FROM returns_summary rs
LEFT JOIN season_sales ws ON EXTRACT(YEAR FROM CURRENT_DATE) = ws.d_year
LEFT JOIN warehouse_activity wa ON TRUE
WHERE 
    (rs.net_loss > 100 OR rs.total_returns > 5)
    AND NOT (rs.max_purchase_estimate IS NULL)
ORDER BY rs.net_loss DESC, rs.total_returns DESC;
