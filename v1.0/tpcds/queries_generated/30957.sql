
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.total_quantity > 1
),
customer_segments AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(s.total_sales) AS segment_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        s.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    t.sales_rank,
    t.i_item_desc,
    t.total_quantity,
    t.total_sales,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.segment_sales
FROM 
    top_sales t
LEFT JOIN 
    customer_segments cs ON t.ws_item_sk = (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_customer_sk IN (
            SELECT c.c_customer_sk 
            FROM customer c 
            WHERE c.c_current_cdemo_sk IN (
                SELECT cd_demo_sk 
                FROM customer_demographics 
                WHERE cd_gender = cs.cd_gender AND cd_marital_status = cs.cd_marital_status 
            )
        )
        LIMIT 1
    )
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
