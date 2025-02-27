
WITH RECURSIVE sales_data AS (
    SELECT 
        s_store_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales 
    JOIN store ON web_sales.ws_warehouse_sk = store.s_store_sk
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY s_store_sk, ws_item_sk
),
high_value_items AS (
    SELECT 
        s_store_sk,
        ws_item_sk,
        total_quantity,
        total_profit
    FROM sales_data
    WHERE rank <= 10
),
customer_info AS (
    SELECT 
        c.customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS aggregate_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN high_value_items hvi ON ws.ws_item_sk = hvi.ws_item_sk
    GROUP BY c.customer_sk, cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        ci.customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.order_count,
        ci.aggregate_profit,
        CASE 
            WHEN ci.aggregate_profit > 5000 THEN 'High Value Customer'
            WHEN ci.aggregate_profit > 1000 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer' 
        END AS customer_category
    FROM customer_info ci
)
SELECT 
    fr.customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.order_count,
    fr.aggregate_profit,
    fr.customer_category,
    COALESCE(ft.purchase_count, 0) AS total_purchases,
    COALESCE(ft.return_count, 0) AS total_returns,
    COALESCE(ft.return_count, 0) / NULLIF(COALESCE(ft.purchase_count, 1), 0) AS return_ratio
FROM final_report fr
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS purchase_count,
        SUM(CASE WHEN sr_returned_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS return_count
    FROM web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
    GROUP BY ws_bill_customer_sk
) ft ON fr.customer_sk = ft.ws_bill_customer_sk
ORDER BY fr.aggregate_profit DESC;
