
WITH RECURSIVE sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM
        catalog_sales
    GROUP BY
        cs_sold_date_sk, cs_item_sk
),
aggregated_sales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        SUM(sd.total_quantity) AS qty_sold,
        SUM(sd.total_profit) AS profit_sold
    FROM
        sales_data sd
    GROUP BY
        sd.ws_sold_date_sk, sd.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_analysis AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
final_metrics AS (
    SELECT
        ag.ws_item_sk,
        ag.qty_sold,
        ag.profit_sold,
        COALESCE(ra.total_returns, 0) AS total_returns,
        COALESCE(ra.total_return_value, 0) AS total_return_value,
        CASE 
            WHEN ra.total_returns = 0 THEN NULL
            ELSE ROUND((ag.profit_sold / ra.total_returns), 2) 
        END AS profit_per_return
    FROM 
        aggregated_sales ag
    LEFT JOIN returns_analysis ra ON ag.ws_item_sk = ra.wr_item_sk
)
SELECT
    fm.ws_item_sk,
    fm.qty_sold,
    fm.profit_sold,
    fm.total_returns,
    fm.total_return_value,
    fm.profit_per_return,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    final_metrics fm
JOIN customer_info ci ON ci.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = fm.ws_item_sk
)
ORDER BY 
    fm.profit_sold DESC,
    fm.qty_sold DESC;
