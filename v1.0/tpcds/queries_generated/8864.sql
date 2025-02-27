
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discounts,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY w.w_warehouse_name, d.d_year
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
warehouse_analysis AS (
    SELECT 
        w.w_warehouse_name,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS warehouse_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS warehouse_returns
    FROM warehouse w
    LEFT JOIN store_sales ss ON ss.ss_store_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_name
)
SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_sales,
    ss.total_discounts,
    ss.total_transactions,
    ss.avg_net_profit,
    cs.total_web_sales,
    cs.total_web_orders,
    wa.warehouse_sales,
    wa.warehouse_returns
FROM sales_summary ss
JOIN customer_summary cs ON cs.total_web_sales > 10000
JOIN warehouse_analysis wa ON wa.w_warehouse_name = ss.w_warehouse_name
ORDER BY ss.d_year, ss.total_sales DESC;
