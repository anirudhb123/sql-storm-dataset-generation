
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
sales_summary AS (
    SELECT 
        ca_state,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        sales_data
    LEFT JOIN 
        customer ON ws_item_sk = c_customer_sk
    LEFT JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY 
        ca_state
),
high_performing_states AS (
    SELECT 
        ca_state,
        total_sales,
        avg_net_profit,
        unique_items_sold
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
),
calculated_returns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
combined_results AS (
    SELECT 
        hp.ca_state,
        hp.total_sales,
        hp.avg_net_profit,
        hp.unique_items_sold,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        hp.total_sales - COALESCE(cr.total_return_value, 0) AS net_sales
    FROM 
        high_performing_states hp
    LEFT JOIN 
        calculated_returns cr ON hp.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cr.sr_store_sk LIMIT 1))
)
SELECT 
    ca_state,
    total_sales,
    avg_net_profit,
    unique_items_sold,
    total_returns,
    total_return_value,
    net_sales
FROM 
    combined_results
WHERE 
    total_sales > 10000 AND unique_items_sold > 5
ORDER BY 
    net_sales DESC
LIMIT 20;
