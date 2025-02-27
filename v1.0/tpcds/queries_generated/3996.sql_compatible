
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws_item_sk
),
TopSales AS (
    SELECT
        web_site_sk,
        ws_item_sk
    FROM RankedSales
    WHERE sales_rank <= 10
),
SalesDetails AS (
    SELECT
        ts.web_site_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_ship_mode_sk) AS max_ship_mode
    FROM TopSales ts
    JOIN web_sales ws ON ts.web_site_sk = ws.ws_web_site_sk AND ts.ws_item_sk = ws.ws_item_sk
    JOIN item i ON ts.ws_item_sk = i.i_item_sk
    GROUP BY ts.web_site_sk, i.i_item_id, i.i_item_desc
),
SalesWithShipping AS (
    SELECT
        sd.web_site_sk,
        sd.i_item_id,
        sd.i_item_desc,
        sd.total_quantity_sold,
        sd.total_net_paid,
        sd.total_orders,
        sm.sm_type AS ship_mode_type,
        sm.sm_carrier AS ship_carrier
    FROM SalesDetails sd
    LEFT JOIN ship_mode sm ON sd.max_ship_mode = sm.sm_ship_mode_sk
)
SELECT
    sd.web_site_sk,
    sd.i_item_id,
    sd.i_item_desc,
    sd.total_quantity_sold,
    sd.total_net_paid,
    sd.total_orders,
    COALESCE(sd.ship_mode_type, 'Unknown') AS ship_mode_type,
    COALESCE(sd.ship_carrier, 'N/A') AS ship_carrier,
    CASE 
        WHEN sd.total_net_paid > 1000 THEN 'High Value'
        WHEN sd.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_value_category
FROM SalesWithShipping sd
ORDER BY sd.total_net_paid DESC;
