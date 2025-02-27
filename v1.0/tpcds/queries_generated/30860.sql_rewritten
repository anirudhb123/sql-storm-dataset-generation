WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        0 AS level
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND i.i_rec_end_date >= cast('2002-10-01' as date)

    UNION ALL

    SELECT 
        i.i_item_sk,
        i.i_item_id,
        CONCAT(ih.i_item_desc, ' > ', i.i_item_desc),
        i.i_current_price,
        ih.level + 1
    FROM 
        item i
    JOIN 
        item_hierarchy ih ON i.i_brand_id = ih.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND i.i_rec_end_date >= cast('2002-10-01' as date)
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        ws.ws_item_sk
),
returns_data AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_sold,
    COALESCE(rd.total_returns, 0) AS total_returns,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) AS net_sales,
    RANK() OVER (ORDER BY (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) DESC) AS sales_rank,
    (SELECT COUNT(DISTINCT c.c_customer_id) 
     FROM customer c 
     JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
     WHERE ws.ws_item_sk = ih.i_item_sk) AS unique_customers
FROM 
    item_hierarchy ih
LEFT JOIN 
    sales_data sd ON ih.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    returns_data rd ON ih.i_item_sk = rd.sr_item_sk
WHERE 
    COALESCE(sd.total_sales, 0) > 0 OR COALESCE(rd.total_returns, 0) > 0
ORDER BY 
    net_sales DESC
LIMIT 10;