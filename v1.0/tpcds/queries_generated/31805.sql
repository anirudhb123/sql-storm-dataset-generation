
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    
    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
item_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
total_sales_by_gender AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) as rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc, i.i_current_price
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.level,
    ts.i_item_desc,
    ts.i_current_price,
    ts.rank,
    tbg.total_sales AS gender_sales
FROM 
    customer_hierarchy ch
LEFT JOIN 
    top_items ts ON ch.c_customer_sk = ts.i_item_id
LEFT JOIN 
    total_sales_by_gender tbg ON ch.cd_gender = tbg.cd_gender
WHERE 
    ch.level <= 3
ORDER BY 
    ch.level, gender_sales DESC;
