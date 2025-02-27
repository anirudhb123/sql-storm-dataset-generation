
WITH sales_summary AS (
    SELECT
        ws.web_site_id,
        cd.gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY
        ws.web_site_id, cd.gender
),
warehouse_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM
        inventory inv
    JOIN
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_id
),
promotion_summary AS (
    SELECT
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM
        promotion p
    JOIN
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        p.p_promo_name
)
SELECT
    ss.web_site_id,
    ss.gender,
    ss.total_sales,
    ss.avg_net_profit,
    ss.order_count,
    ss.customer_count,
    ws.total_inventory,
    ws.avg_inventory,
    ps.promo_order_count,
    ps.promo_sales
FROM
    sales_summary ss
JOIN
    warehouse_summary ws ON ss.web_site_id = ws.w_warehouse_id
LEFT JOIN
    promotion_summary ps ON ss.web_site_id = ps.promo_order_count
ORDER BY
    ss.total_sales DESC, ss.gender;
