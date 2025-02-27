
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), top_sales AS (
    SELECT 
        ss.ws_item_sk,
        i.i_product_name,
        ss.total_quantity,
        ss.total_profit
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.rank <= 10
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), best_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.order_count,
        ci.total_net_profit,
        DENSE_RANK() OVER (ORDER BY ci.total_net_profit DESC) AS profit_rank
    FROM 
        customer_info ci
), classified_customers AS (
    SELECT 
        *,
        CASE 
            WHEN total_net_profit > 1000 THEN 'High Value'
            WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        best_customers
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_net_profit,
    tc.customer_value,
    ts.i_product_name,
    ts.total_quantity
FROM 
    classified_customers tc
JOIN 
    top_sales ts ON ts.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = tc.c_customer_sk
    )
ORDER BY 
    tc.total_net_profit DESC, 
    ts.total_quantity DESC;
