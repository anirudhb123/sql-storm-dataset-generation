
WITH RECURSIVE sales_ranks AS (
    SELECT 
        ws_item_sk,
        ws_order_number, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit
    FROM web_sales
    WHERE ws_sales_price > 0
), 
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL
), 
top_items AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
), 
sales_summary AS (
    SELECT 
        ci.c_customer_id,
        ci.ca_city,
        COALESCE(sr.total_returns, 0) AS total_returns,
        sr.return_count,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer_data ci
    LEFT JOIN web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    LEFT JOIN top_items sr ON ws.ws_item_sk = sr.sr_item_sk
    GROUP BY ci.c_customer_id, ci.ca_city, sr.total_returns, sr.return_count
),
final_report AS (
    SELECT
        s.c_customer_id,
        s.ca_city,
        s.total_returns,
        s.return_count,
        s.order_count,
        s.total_profit,
        CASE 
            WHEN s.order_count > 10 THEN 'High Value'
            WHEN s.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM sales_summary s
),
profit_rank AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM final_report
)
SELECT 
    fr.c_customer_id,
    fr.ca_city,
    fr.total_returns,
    fr.return_count,
    fr.order_count,
    fr.total_profit,
    fr.customer_value,
    CASE 
        WHEN fr.profit_rank <= 10 THEN 'Top 10 Profit Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM profit_rank fr
WHERE fr.total_profit IS NOT NULL
ORDER BY fr.total_profit DESC, fr.c_customer_id
FETCH FIRST 100 ROWS ONLY;
