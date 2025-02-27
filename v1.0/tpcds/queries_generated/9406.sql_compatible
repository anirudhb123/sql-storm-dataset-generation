
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M' AND
        cd.cd_purchase_estimate > 500
    GROUP BY
        ws.web_site_sk, ws_order_number
),
TopWebsites AS (
    SELECT
        sales_rank,
        web_site_sk,
        total_sales,
        order_count
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
)
SELECT
    w.web_warehouse_name AS website_name,
    tw.total_sales,
    tw.order_count,
    SUM(CASE WHEN ws.ws_ship_mode_sk = sm.sm_ship_mode_sk THEN 1 ELSE 0 END) AS shipping_method_count,
    AVG(ws.ws_net_profit) AS average_net_profit
FROM
    TopWebsites tw
JOIN
    warehouse w ON tw.web_site_sk = w.w_warehouse_sk
JOIN
    web_sales ws ON tw.web_site_sk = ws.ws_web_site_sk
JOIN
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    w.web_warehouse_name, tw.total_sales, tw.order_count
ORDER BY
    tw.total_sales DESC;
