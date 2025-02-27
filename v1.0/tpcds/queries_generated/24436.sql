
WITH RECURSIVE frequent_item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 1000
),
item_with_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        fi.total_sales,
        ROW_NUMBER() OVER (ORDER BY fi.total_sales DESC) AS rank,
        COALESCE((SELECT COUNT(DISTINCT sr_ticket_number) 
                  FROM store_returns sr 
                  WHERE sr.sr_item_sk = i.i_item_sk), 0) AS return_count,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Unavailable'
            ELSE FORMAT(i.i_current_price, 'C')
        END AS formatted_price
    FROM 
        item i
    JOIN 
        frequent_item_sales fi ON i.i_item_sk = fi.ws_item_sk
),
promotions_with_counts AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT cs.cs_order_number) AS sales_count,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_id
),
sales_by_month AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS monthly_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    iw.i_item_id,
    iw.i_item_desc,
    iw.total_sales,
    iw.return_count,
    iw.formatted_price,
    pm.p_promo_id,
    pm.sales_count,
    pm.total_profit,
    sbm.d_year,
    sbm.d_month_seq,
    sbm.monthly_profit,
    CASE 
        WHEN sbm.monthly_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    item_with_details iw
LEFT JOIN 
    promotions_with_counts pm ON iw.rank <= 10 AND pm.sales_count > 0
FULL OUTER JOIN 
    sales_by_month sbm ON iw.rank = 1
WHERE 
    iw.formatted_price != 'Price Unavailable' 
    AND iw.return_count < 5
ORDER BY 
    iw.total_sales DESC, pm.total_profit DESC NULLS LAST
LIMIT 100
OFFSET 50;
