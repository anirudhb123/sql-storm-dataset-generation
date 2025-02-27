
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        w.w_warehouse_sk, 
        w.w_warehouse_name, 
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
    UNION ALL
    SELECT 
        wh.warehouse_sk,
        wh.warehouse_name,
        sh.total_sales_profit + SUM(ws.ws_net_profit) AS total_sales_profit
    FROM sales_hierarchy sh
    JOIN warehouse wh ON sh.w_warehouse_sk = wh.w_warehouse_sk
    JOIN web_sales ws ON wh.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY wh.warehouse_sk, wh.warehouse_name, sh.total_sales_profit
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer_data c
    WHERE rank <= 10
),
returns_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    wh.w_warehouse_name,
    COALESCE(sh.total_sales_profit, 0) AS total_sales_profit,
    COUNT(DISTINCT tc.c_customer_sk) AS top_customer_count,
    COALESCE(rs.total_returned, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    COALESCE(rs.total_return_tax, 0) AS total_return_tax
FROM sales_hierarchy sh
LEFT JOIN top_customers tc ON tc.c_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk 
    FROM web_sales ws 
    WHERE ws.ws_warehouse_sk = sh.w_warehouse_sk
)
LEFT JOIN returns_summary rs ON rs.cr_item_sk IN (
    SELECT DISTINCT ws.ws_item_sk 
    FROM web_sales ws 
    WHERE ws.ws_warehouse_sk = sh.w_warehouse_sk
)
JOIN warehouse wh ON sh.w_warehouse_sk = wh.w_warehouse_sk
GROUP BY wh.w_warehouse_name, sh.total_sales_profit
ORDER BY total_sales_profit DESC;
