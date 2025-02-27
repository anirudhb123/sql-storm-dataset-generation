
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 4000 AND 5000
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
top_sales AS (
    SELECT
        ss.ws_order_number,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount
    FROM 
        sales_summary ss
    WHERE 
        ss.rnk = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
order_info AS (
    SELECT 
        os.ws_order_number,
        COUNT(DISTINCT os.ws_item_sk) AS total_items,
        SUM(os.ws_ext_sales_price) AS total_order_amount
    FROM 
        web_sales os
    GROUP BY 
        os.ws_order_number
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    oi.total_items,
    oi.total_order_amount,
    COALESCE(TOTAL_SALES.total_sales, 0) AS highest_order_sales,
    COALESCE(TOTAL_SALES.total_discount, 0) AS highest_order_discount
FROM 
    customer_info ci
LEFT JOIN 
    order_info oi ON ci.c_customer_sk = oi.ws_order_number
LEFT JOIN 
    top_sales TOTAL_SALES ON oi.ws_order_number = TOTAL_SALES.ws_order_number
WHERE 
    ci.total_profit > 1000
ORDER BY 
    highest_order_sales DESC
FETCH FIRST 100 ROWS ONLY;
