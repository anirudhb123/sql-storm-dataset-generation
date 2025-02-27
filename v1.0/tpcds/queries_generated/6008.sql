
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT w.w_warehouse_id) AS total_warehouses,
        DATE(d.d_date) AS sales_date
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        ws.web_site_id, DATE(d.d_date)
),
CustomerStats AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT sd.total_orders) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        SalesData sd ON c.c_customer_sk = sd.web_site_id -- Assuming mapping
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT sd.web_site_id) AS used_websites,
        SUM(sd.total_sales) AS warehouse_sales
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN
        SalesData sd ON ws.ws_web_site_sk = sd.web_site_id
    GROUP BY
        w.w_warehouse_id
)

SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.order_count,
    ws.warehouse_sales,
    ws.used_websites
FROM
    CustomerStats cs
JOIN
    WarehouseStats ws ON cs.total_sales > 1000 -- Filter for high-value customers
WHERE
    cs.cd_gender = 'F' AND cs.order_count > 5
ORDER BY
    cs.total_sales DESC;
