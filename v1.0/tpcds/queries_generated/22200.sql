
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.net_profit) AS total_net_profit,
        COUNT(ss.ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.net_profit) DESC) AS rank
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
),
item_info AS (
    SELECT 
        i.item_sk,
        i.item_id,
        i.item_desc,
        COALESCE(i.current_price, 0) AS current_price,
        COALESCE(i.wholesale_cost, 0) AS wholesale_cost,
        LEAD(i.brand_id) OVER (ORDER BY i.item_sk) AS next_item_brand_id
    FROM 
        item i
    WHERE 
        i.rec_start_date <= CURRENT_DATE AND (i.rec_end_date >= CURRENT_DATE OR i.rec_end_date IS NULL)
),
top_sales AS (
    SELECT 
        sd.sold_date_sk,
        sd.item_sk,
        sd.total_net_profit,
        sd.total_sales,
        ii.item_desc,
        ii.current_price,
        ii.wholesale_cost,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS top_rank
    FROM 
        sales_data sd
    JOIN 
        item_info ii ON sd.item_sk = ii.item_sk
    WHERE 
        sd.total_net_profit > 1000
)
SELECT 
    ts.sold_date_sk,
    ts.item_sk,
    ts.item_desc,
    ts.total_net_profit,
    ts.total_sales,
    ts.current_price,
    ts.wholesale_cost,
    CASE 
        WHEN ts.total_sales > 10 THEN 'High Volume'
        WHEN ts.total_sales BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category,
    COALESCE(
        (SELECT AVG(wm.warehouse_sq_ft) 
         FROM warehouse wm 
         WHERE wm.warehouse_sk IN 
            (SELECT ss.store_sk 
             FROM store_sales ss 
             WHERE ss.item_sk = ts.item_sk)
        ), 
        0
    ) AS avg_warehouse_size
FROM 
    top_sales ts
WHERE 
    ts.top_rank <= 5
ORDER BY 
    ts.total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
