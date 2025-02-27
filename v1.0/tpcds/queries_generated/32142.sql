
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 31
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 31
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
sales_summary AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        COALESCE(web.total_quantity, 0) AS web_quantity,
        COALESCE(catalog.total_quantity, 0) AS catalog_quantity,
        (COALESCE(web.total_sales, 0) + COALESCE(catalog.total_sales, 0)) AS total_sales
    FROM 
        item 
    LEFT JOIN (
        SELECT 
            ws_item_sk, 
            SUM(ws_quantity) AS total_quantity, 
            SUM(ws_net_paid_inc_tax) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
    ) web ON item.i_item_sk = web.ws_item_sk
    LEFT JOIN (
        SELECT 
            cs_item_sk, 
            SUM(cs_quantity) AS total_quantity, 
            SUM(cs_net_paid_inc_tax) AS total_sales
        FROM 
            catalog_sales
        GROUP BY 
            cs_item_sk
    ) catalog ON item.i_item_sk = catalog.cs_item_sk
),
top_sales AS (
    SELECT 
        i_item_id,
        i_item_desc,
        web_quantity + catalog_quantity AS total_quantity,
        total_sales
    FROM 
        sales_summary
    WHERE 
        (web_quantity + catalog_quantity) > 0
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    CUME_DIST() OVER (ORDER BY ts.total_sales) AS sales_rank
FROM 
    top_sales ts
JOIN 
    customer c ON c.c_current_cdemo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M' AND cd_gender = 'F' LIMIT 1)
WHERE 
    c.c_preferred_cust_flag = 'Y' 
    AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk = (SELECT sr_store_sk FROM store_returns sr WHERE sr_item_sk = ts.i_item_id LIMIT 1)
    )
ORDER BY 
    ts.total_sales DESC;
