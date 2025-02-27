
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws.web_site_sk
    UNION ALL
    SELECT 
        ss.web_site_sk,
        ss.total_orders + rs.total_orders,
        ss.total_net_profit + rs.total_net_profit
    FROM 
        sales_summary ss
    JOIN 
        sales_summary rs ON ss.web_site_sk = rs.web_site_sk AND ss.total_orders > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_dep_count, 0) AS dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
date_range AS (
    SELECT 
        d.d_date_sk, 
        d.d_date 
    FROM 
        date_dim d 
    WHERE 
        d.d_year = 2023
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.dep_count,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    COALESCE(is.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(is.total_profit, 0) AS total_profit,
    CASE WHEN ci.hd_income_band_sk IS NULL THEN 'Unknown Income Band'
         ELSE CONCAT('Income Band ', ci.hd_income_band_sk) END AS income_band
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.web_site_sk
LEFT JOIN 
    item_sales is ON ci.c_customer_sk = is.ws_item_sk
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
    AND (ss.total_net_profit > 1000 OR is.total_profit > 500)
ORDER BY 
    total_net_profit DESC, 
    total_quantity_sold DESC;
