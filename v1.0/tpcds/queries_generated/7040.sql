
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk AS sales_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        cs.cs_ext_sales_price AS catalog_sales,
        sr.sr_return_quantity AS store_returns
    FROM
        web_sales ws
    LEFT JOIN
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
    GROUP BY
        sales_date
),
customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk
)
SELECT 
    ds.d_date AS date,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_net_profit,
    cs.total_customers,
    cs.avg_purchase_estimate
FROM
    date_dim ds
LEFT JOIN
    sales_summary ss ON ds.d_date_sk = ss.sales_date
LEFT JOIN
    customer_summary cs ON ss.sales_date BETWEEN ds.d_date - INTERVAL '30 DAY' AND ds.d_date
WHERE
    ds.d_year = 2023
ORDER BY
    ds.d_date;
