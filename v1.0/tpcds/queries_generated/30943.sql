
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL 
        AND c.c_first_sales_date_sk IS NOT NULL 
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
    UNION ALL
    SELECT 
        sh.c_customer_sk, 
        sh.c_customer_id, 
        sh.c_first_name, 
        sh.c_last_name, 
        sh.cd_marital_status,
        sh.cd_gender,
        COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_profit AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY sh.cd_marital_status ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_profit DESC) AS rank
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        sh.c_customer_sk, sh.c_customer_id, sh.c_first_name, sh.c_last_name, sh.cd_marital_status, sh.cd_gender, sh.total_profit
)
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sh.total_profit,
    CASE 
        WHEN sh.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_segment
FROM 
    sales_hierarchy sh
JOIN 
    customer c ON sh.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    sh.rank <= 10
ORDER BY 
    sh.total_profit DESC;

WITH item_summary AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    isum.total_sold, 
    isum.avg_price,
    isum.max_price,
    isum.min_price 
FROM 
    item i
INNER JOIN 
    item_summary isum ON i.i_item_id = isum.i_item_id
WHERE 
    isum.total_sold > 0
UNION ALL 
SELECT 
    NULL AS i_item_id, 
    'Total Sales' AS i_item_desc, 
    COUNT(*) AS total_sold, 
    SUM(isum.avg_price) AS avg_price,
    MAX(isum.max_price) AS max_price,
    MIN(isum.min_price) AS min_price
FROM 
    item_summary isum;
