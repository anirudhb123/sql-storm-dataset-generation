
WITH sales_data AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ship_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ABS(COALESCE(cd.cd_dep_count, 0) - COALESCE(hd.hd_dep_count, 0)) AS dep_diff
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
return_stats AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS unique_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT 
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ws.total_sales_quantity, 0) AS total_sales,
    COALESCE(rt.total_returned, 0) AS total_returns,
    CASE 
        WHEN COALESCE(rt.total_returns, 0) > 0 THEN 'Returned Customer'
        ELSE 'Active Customer'
    END AS customer_status,
    (SELECT AVG(ws_ext_sales_price) 
     FROM web_sales 
     WHERE ws_item_sk = wd.ws_item_sk) AS avg_sales_price
FROM customer_info ci
LEFT JOIN (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_sales_quantity
    FROM sales_data sd
    WHERE sd.rn = 1
    GROUP BY sd.ws_item_sk
) ws ON ws.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales)
LEFT JOIN return_stats rt ON rt.wr_returning_customer_sk = ci.c_customer_sk
ORDER BY ci.cd_gender, total_sales DESC;
