
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ss_store_sk, ss_sold_date_sk, ss_item_sk

    UNION ALL

    SELECT 
        sh.ss_store_sk,
        sh.ss_sold_date_sk,
        sh.ss_item_sk,
        sh.total_quantity + s.ss_quantity AS total_quantity,
        sh.total_sales + s.ss_net_paid AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales s ON sh.ss_item_sk = s.ss_item_sk AND sh.ss_store_sk = s.ss_store_sk
    WHERE 
        s.ss_sold_date_sk > sh.ss_sold_date_sk
),

customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),

store_profit AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss.ss_store_sk
)

SELECT 
    c.c_customer_sk,
    ci.total_net_paid,
    COALESCE(sp.total_store_profit, 0) AS total_profit_by_store,
    sh.total_quantity,
    RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY ci.total_net_paid DESC) AS customer_rank
FROM 
    customer_info ci
JOIN 
    customer c ON ci.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    store_profit sp ON sp.ss_store_sk = c.c_current_addr_sk
LEFT JOIN 
    (SELECT 
         ss_item_sk, 
         total_quantity 
     FROM 
         sales_hierarchy 
     WHERE 
         total_sales > 100) sh ON sh.ss_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = c.c_customer_id LIMIT 1)
WHERE 
    ci.total_net_paid > 1000
ORDER BY 
    ci.total_net_paid DESC;
