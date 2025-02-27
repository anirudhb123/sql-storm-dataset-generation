
WITH sales_summary AS (
    SELECT 
        ws.item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND ws.ws_ship_mode_sk IN (
            SELECT sm_ship_mode_sk
            FROM ship_mode
            WHERE sm_type LIKE '%Express%'
        )
    GROUP BY
        ws.item_sk
),
top_selling_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales_summary.total_quantity,
        sales_summary.total_sales,
        sales_summary.average_profit,
        sales_summary.order_count,
        sales_summary.unique_customers
    FROM 
        sales_summary
    JOIN 
        item ON sales_summary.item_sk = item.i_item_sk
    ORDER BY 
        sales_summary.total_sales DESC
    LIMIT 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    tsi.average_profit,
    tsi.order_count,
    tsi.unique_customers
FROM 
    top_selling_items tsi
JOIN 
    warehouse w ON w.w_warehouse_sk = (
        SELECT ws.ws_warehouse_sk 
        FROM web_sales ws 
        WHERE ws.ws_item_sk = tsi.item_sk 
        ORDER BY ws.ws_sales_price DESC 
        LIMIT 1
    )
WHERE 
    w.w_state = 'CA'
ORDER BY 
    tsi.total_sales DESC;
