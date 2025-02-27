
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND i.i_current_price > 0
    GROUP BY 
        ws.web_site_sk
),
demographic_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate BETWEEN 1000 AND 5000
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    COALESCE(ss.web_site_sk, ds.cd_demo_sk) AS related_id,
    ss.total_net_profit,
    ds.customer_count,
    ds.orders_count,
    ds.total_profit,
    ss.avg_order_value
FROM 
    sales_summary ss
FULL OUTER JOIN 
    demographic_summary ds ON ss.web_site_sk = ds.cd_demo_sk
WHERE 
    (ss.rank = 1 OR ds.customer_count IS NOT NULL)
ORDER BY 
    COALESCE(ss.total_net_profit, 0) DESC,
    COALESCE(ds.total_profit, 0) DESC;
