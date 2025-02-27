
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price, 
        i_brand 
    FROM 
        item
    WHERE 
        i_current_price > 50
    UNION ALL
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price, 
        i.i_brand 
    FROM 
        item_hierarchy ih
    JOIN 
        item i ON ih.i_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price < ih.i_current_price
),
customer_preferences AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sales_price > 100
    GROUP BY 
        c.c_customer_sk
),
sales_performance AS (
    SELECT 
        th.c_customer_sk,
        th.total_profit,
        cp.total_purchases,
        ROW_NUMBER() OVER (PARTITION BY cp.cd_gender ORDER BY th.total_profit DESC) AS profit_rank
    FROM 
        top_customers th
    JOIN 
        customer_preferences cp ON th.c_customer_sk = cp.c_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.cd_gender,
    ih.i_item_desc,
    ih.i_current_price,
    sp.total_profit,
    cp.total_purchases
FROM 
    item_hierarchy ih
JOIN 
    sales_performance sp ON sp.c_customer_sk IN (SELECT DISTINCT c.c_customer_sk FROM customer c)
LEFT JOIN 
    customer_preferences cp ON sp.c_customer_sk = cp.c_customer_sk
WHERE 
    sp.profit_rank <= 10 AND 
    ih.i_brand IS NOT NULL
ORDER BY 
    cp.cd_gender, sp.total_profit DESC;
