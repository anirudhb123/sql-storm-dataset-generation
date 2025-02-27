
WITH RankedSales AS (
    SELECT
        ws_web_site_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_ship_date_sk BETWEEN 
        (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_year = 'Y') 
        AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY 
        ws_web_site_sk
),
CustomerOrders AS (
    SELECT
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_ship_customer_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
ShipModes AS (
    SELECT
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_id
    HAVING
        COUNT(ws.ws_order_number) > 10
)
SELECT
    cs.c_customer_id,
    cs.total_spent,
    COUNT(DISTINCT so.ss_ticket_number) AS store_order_count,
    rs.total_sales AS website_sales,
    sm.total_orders AS ship_mode_orders
FROM
    CustomerOrders cs
LEFT JOIN
    store_sales so ON cs.c_customer_id = so.ss_customer_sk
LEFT JOIN
    RankedSales rs ON cs.c_customer_id = rs.ws_web_site_sk
JOIN
    ShipModes sm ON sm.sm_ship_mode_id = (SELECT sm.sm_ship_mode_id FROM ship_mode sm WHERE sm.sm_ship_mode_sk = so.ss_ship_mode_sk)
WHERE
    cs.total_spent IS NOT NULL
GROUP BY
    cs.c_customer_id, cs.total_spent, rs.total_sales, sm.total_orders
HAVING
    cs.total_spent > 1000 OR (rs.total_sales IS NOT NULL AND rs.total_sales > 5000)
ORDER BY
    cs.total_spent DESC, website_sales DESC;
