
WITH RECURSIVE MonthlySales AS (
    SELECT 
        s_sold_date_sk,
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY s_sold_date_sk) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        s_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS overall_sales
    FROM 
        MonthlySales
    WHERE 
        sales_rank <= 3
    GROUP BY 
        ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales + cs.total_store_sales AS total_sales,
    ti.overall_sales AS top_item_sales,
    CASE 
        WHEN cs.total_web_sales > cs.total_store_sales THEN 'Web'
        WHEN cs.total_web_sales < cs.total_store_sales THEN 'Store'
        ELSE 'Equal'
    END AS preferred_channel
FROM 
    CustomerSales cs
LEFT JOIN 
    TopItems ti ON ti.ws_item_sk = (SELECT ws_item_sk FROM web_sales ORDER BY ws_net_profit DESC LIMIT 1)
WHERE 
    (cs.total_web_sales + cs.total_store_sales) > 10000
ORDER BY 
    total_sales DESC
LIMIT 50;
