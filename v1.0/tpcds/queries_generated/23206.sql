
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 1100
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        i.i_current_price,
        CASE 
            WHEN i.i_current_price IS NOT NULL THEN ROUND(i.i_current_price * 1.2, 2) 
            ELSE NULL 
        END AS adjusted_price,
        COALESCE(NULLIF(i.i_item_desc, ''), 'No Description') AS item_description
    FROM 
        item i
),
sales_analysis AS (
    SELECT 
        r.ws_item_sk,
        r.total_orders,
        r.total_revenue,
        id.i_item_id,
        id.item_description,
        id.adjusted_price
    FROM 
        ranked_sales r
    JOIN 
        item_details id ON r.ws_item_sk = id.i_item_id
    WHERE 
        r.revenue_rank <= 10
),
store_revenue AS (
    SELECT 
        ss.store_sk,
        SUM(ss_ext_sales_price) AS store_revenue,
        COUNT(DISTINCT ss_ticket_number) AS unique_transactions
    FROM 
        store_sales ss
    WHERE 
        ss_sold_date_sk BETWEEN 1000 AND 1100
    GROUP BY 
        ss.store_sk
)
SELECT 
    sa.i_item_id,
    sa.item_description,
    sa.total_orders,
    sa.total_revenue,
    COALESCE(st.store_revenue, 0) AS revenue_from_stores,
    CASE 
        WHEN sa.total_revenue > 0 THEN ROUND((COALESCE(st.store_revenue, 0) / sa.total_revenue) * 100, 2)
        ELSE 0 
    END AS store_revenue_percentage,
    (SELECT 
        COUNT(DISTINCT c.c_customer_id)
     FROM 
        customer c 
     WHERE 
        c.c_current_cdemo_sk IS NOT NULL AND 
        c.c_customer_sk IN (SELECT DISTINCT wr_returning_customer_sk FROM web_returns wr)
    ) AS returning_customers
FROM 
    sales_analysis sa
LEFT JOIN 
    store_revenue st ON st.store_sk = sa.ws_item_sk  -- Assuming store_sk references item_sk for this bizarre case
ORDER BY 
    sa.total_revenue DESC;
