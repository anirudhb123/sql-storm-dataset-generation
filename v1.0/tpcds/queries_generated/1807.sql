
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_quantity,
        ss_sales_price,
        ss_sold_date_sk,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk, ss_quantity, ss_sales_price, ss_sold_date_sk
),
monthly_sales AS (
    SELECT 
        to_char(dd.d_date, 'YYYY-MM') AS month,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON ws.ws_ship_date_sk = dd.d_date_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_ship_date_sk = dd.d_date_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_sold_date_sk = dd.d_date_sk
    GROUP BY 
        month
),
top_items AS (
    SELECT 
        isnull(c.c_first_name || ' ' || c.c_last_name, 'Unknown') AS customer_name,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 
        customer_name, i.i_item_desc
    HAVING 
        SUM(ss.ss_net_profit) > 0
)
SELECT 
    ms.month,
    COALESCE(ms.total_web_sales, 0) AS web_sales,
    COALESCE(ms.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(ms.total_store_sales, 0) AS store_sales,
    ti.customer_name,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_net_profit
FROM 
    monthly_sales ms
FULL OUTER JOIN 
    top_items ti ON ti.total_quantity_sold = (
        SELECT MAX(total_quantity_sold)
        FROM top_items
    )
ORDER BY 
    month DESC, total_net_profit DESC
LIMIT 10;
