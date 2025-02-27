
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.total_quantity,
        sales.total_revenue,
        COALESCE(sales.rank, 0) AS rank
    FROM 
        item
    LEFT JOIN 
        RankedSales sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        item.i_current_price IS NOT NULL
    ORDER BY 
        sales.total_revenue DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_revenue,
    CASE 
        WHEN ti.rank = 1 THEN 'Top Seller' 
        WHEN ti.rank BETWEEN 2 AND 5 THEN 'High Performer' 
        WHEN ti.rank BETWEEN 6 AND 10 THEN 'Moderate Performer' 
        ELSE 'Not a Performer' 
    END AS performance_category,
    (SELECT COUNT(DISTINCT c_customer_sk) 
     FROM web_sales ws 
     WHERE ws.ws_item_sk = ti.i_item_sk AND
           ws.ws_bill_customer_sk IS NOT NULL) AS num_unique_buyers,
    (SELECT AVG(total_revenue_per_sale) 
     FROM (
         SELECT 
             ws.ws_order_number,
             SUM(ws.ws_net_paid) AS total_revenue_per_sale
         FROM 
             web_sales AS ws 
         WHERE 
             ws.ws_item_sk = ti.i_item_sk 
         GROUP BY 
             ws.ws_order_number
     ) AS subquery) AS avg_revenue_per_order
FROM 
    TopItems ti 
LEFT JOIN 
    store_sales ss ON ti.i_item_sk = ss.ss_item_sk 
GROUP BY 
    ti.i_item_id, ti.i_product_name, ti.total_quantity, ti.total_revenue, ti.rank
HAVING 
    AVG(ss.ss_net_profit) > 
    (SELECT AVG(ss_net_profit) FROM store_sales) 
    OR 
    COUNT(ss.ss_ticket_number) < 
    (SELECT COUNT(ss_ticket_number) FROM store_sales WHERE ss_ticket_number IS NOT NULL) / 2
ORDER BY 
    ti.total_revenue DESC
