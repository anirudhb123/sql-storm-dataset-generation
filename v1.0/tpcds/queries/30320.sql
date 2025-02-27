
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 50
),
recent_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1)
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        ca_state,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    WHERE 
        ca_city IS NOT NULL
    GROUP BY 
        ca_state
),
combined_summary AS (
    SELECT
        s.ss_item_sk,
        COALESCE(ss.total_sold, 0) AS total_sold,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(rs.total_sales_price, 0) AS total_sales_price,
        COALESCE(rs.order_count, 0) AS order_count,
        cd.ca_state,
        cd.customer_count,
        cd.total_estimate,
        cd.highest_credit_rating
    FROM 
        store_sales s
    LEFT JOIN 
        sales_summary ss ON s.ss_item_sk = ss.ws_item_sk
    LEFT JOIN 
        recent_sales rs ON s.ss_item_sk = rs.ws_item_sk
    LEFT JOIN 
        customer_data cd ON cd.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = s.ss_customer_sk)
    WHERE 
        s.ss_sold_date_sk BETWEEN 20230101 AND 20231231
)
SELECT 
    c.ca_state,
    SUM(c.customer_count) AS total_customers,
    AVG(c.total_estimate) AS avg_purchase_estimate,
    SUM(c.total_profit) AS total_profit_generated,
    SUM(c.total_sold) AS total_units_sold,
    SUM(c.order_count) AS total_orders,
    STRING_AGG(DISTINCT c.highest_credit_rating, ', ') AS unique_credit_ratings
FROM 
    combined_summary c
WHERE 
    c.total_profit > 0
GROUP BY 
    c.ca_state
HAVING 
    COUNT(DISTINCT c.ss_item_sk) > 5
ORDER BY 
    total_profit_generated DESC;
