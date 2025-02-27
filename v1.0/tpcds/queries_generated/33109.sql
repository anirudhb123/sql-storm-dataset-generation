
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ch.level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON c.c_customer_sk = ch.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count > 0
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name, 
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        i.i_item_sk, i.i_product_name
),
sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_sk
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    ch.cd_purchase_estimate,
    COALESCE(i.total_sales, 0) AS item_total_sales,
    COALESCE(i.avg_discount, 0) AS item_avg_discount,
    ss.total_net_paid AS store_total_net_paid,
    ss.total_transactions AS store_total_transactions,
    ROW_NUMBER() OVER (PARTITION BY ch.cd_gender ORDER BY ch.cd_purchase_estimate DESC) AS rank
FROM 
    customer_hierarchy ch
LEFT JOIN 
    item_stats i ON ch.cd_demo_sk = i.i_item_sk
LEFT JOIN 
    sales_summary ss ON ch.c_customer_sk = ss.s_store_sk
WHERE 
    (ch.cd_gender = 'F' OR ch.cd_marital_status = 'M') 
    AND (i.total_sales > 1000 OR ss.total_net_paid > 5000)
ORDER BY 
    rank;
