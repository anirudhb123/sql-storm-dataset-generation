
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2451005 AND 2451015
    GROUP BY 
        cs_bill_customer_sk
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_net_profit) + sh.total_profit,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.cs_bill_customer_sk
    WHERE 
        s.ss_sold_date_sk BETWEEN 2451005 AND 2451015
    GROUP BY 
        s.ss_customer_sk, sh.total_profit, sh.level
),
top_items AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS ranking
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451000 AND 2451010
    GROUP BY 
        i.i_item_id
    HAVING 
        SUM(ws.ws_quantity) > 100
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        d.d_year AS purchase_year,
        COALESCE(cd.cd_gender, 'Unknown') AS gender
    FROM 
        customer c
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.full_name,
    cd.gender,
    sh.total_profit,
    ti.i_item_id,
    ti.total_quantity
FROM 
    customer_data cd
JOIN 
    sales_hierarchy sh ON cd.c_customer_id = sh.cs_bill_customer_sk
JOIN 
    top_items ti ON ti.total_quantity > (
        SELECT AVG(total_quantity) FROM top_items
    )
WHERE 
    sh.level <= 3
    AND sh.total_profit IS NOT NULL
ORDER BY 
    sh.total_profit DESC, 
    ti.total_quantity DESC;
