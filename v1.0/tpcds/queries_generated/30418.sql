
WITH RECURSIVE SalesTrend AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        st.total_sales + SUM(ws.ws_quantity) AS total_sales,
        st.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesTrend st ON ws.ws_sold_date_sk = st.ws_sold_date_sk - 1 AND ws.ws_item_sk = st.ws_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, st.total_sales, st.level
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_sales_price) AS total_sales_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_current_year = 'Y') AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_sales_price DESC
    LIMIT 10
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    t.total_sales_price,
    CASE 
        WHEN t.total_sales_price IS NULL THEN 'No sales' 
        ELSE 'Sales exist'
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY t.total_sales_price DESC) AS rank,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IN 
        (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F')) AS female_customer_count
FROM 
    TopItems t
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = t.i_item_id LIMIT 1)
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_credit_rating IS NOT NULL
AND 
    EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk IN 
               (SELECT DISTINCT ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = t.i_item_id))
ORDER BY 
    total_sales_price DESC;
