
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_amount_refunded
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk, cr_item_sk
),
WebSales AS (
    SELECT 
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM web_sales
    GROUP BY ws_ship_customer_sk, ws_item_sk
),
PotentialWhales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        COALESCE(SUM(cr.total_returned), 0) AS total_returned,
        COALESCE(SUM(ws.total_sold), 0) AS total_sold,
        COALESCE(SUM(ws.total_sales_amount), 0) AS total_sales_amount,
        CASE 
            WHEN SUM(ws.total_sold) > 100 THEN 'Big Spender'
            WHEN SUM(ws.total_returned) > 50 THEN 'Frequent Returner'
            ELSE 'Regular Customer'
        END AS customer_behavior
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN WebSales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(ss.net_profit) AS total_daily_profit,
        AVG(COALESCE(ss.net_profit, 0)) OVER (ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_profit_last_week
    FROM date_dim d
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_date
)
SELECT 
    pw.c_customer_id,
    pw.c_first_name,
    pw.c_last_name,
    pw.total_returned,
    pw.total_sold,
    pw.total_sales_amount,
    pw.customer_behavior,
    ds.total_daily_profit,
    ds.avg_profit_last_week,
    CASE 
        WHEN ds.total_daily_profit IS NULL THEN 'No Sales Data'
        WHEN ds.avg_profit_last_week IS NULL THEN 'Week Average Not Available'
        ELSE 'Data Available'
    END AS sales_data_status
FROM PotentialWhales pw
JOIN DailySales ds ON ds.d_date = CURRENT_DATE
WHERE 
    pw.total_sales_amount > 100 OR 
    pw.customer_behavior = 'Frequent Returner'
ORDER BY 
    pw.total_sales_amount DESC,
    pw.total_returned ASC;
