
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity_sold,
        ri.total_sales,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        ROW_NUMBER() OVER (ORDER BY ri.total_sales DESC) AS item_rank
    FROM 
        ranked_sales ri
    LEFT JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.rank_sales = 1
)
SELECT 
    ti.item_rank,
    ti.item_description,
    ti.total_quantity_sold,
    ti.total_sales,
    CASE 
        WHEN ti.total_sales > 1000 THEN 'High Sales'
        WHEN ti.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    top_items ti
WHERE 
    ti.total_quantity_sold > 10
ORDER BY 
    ti.total_sales DESC
LIMIT 10;

-- To include customers associated with the top selling items
WITH customer_sales AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales ws
    WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM top_items)
    GROUP BY 
        ws.ws_ship_customer_sk
),
top_customers AS (
    SELECT 
        cs.ws_ship_customer_sk,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.customer_rank,
    tc.ws_ship_customer_sk,
    tc.total_spent
FROM 
    top_customers tc
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_spent DESC;
