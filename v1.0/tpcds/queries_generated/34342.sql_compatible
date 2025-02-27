
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
),
Top_Sales AS (
    SELECT 
        s.s_store_id,
        SUM(sc.total_sales) AS top_item_sales,
        SUM(sc.total_revenue) AS total_revenue
    FROM 
        store s
    LEFT JOIN 
        Sales_CTE sc ON s.s_store_sk = sc.ss_store_sk
    WHERE 
        sc.sales_rank <= 10
    GROUP BY 
        s.s_store_id
),
Ship_Mode_CTE AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        ship_mode sm
    JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    t.s_store_id,
    t.top_item_sales,
    t.total_revenue,
    COALESCE(sm.order_count, 0) AS ship_mode_order_count,
    CASE 
        WHEN t.total_revenue > 100000 THEN 'High Revenue' 
        WHEN t.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    Top_Sales t
LEFT JOIN 
    Ship_Mode_CTE sm ON t.s_store_id = sm.sm_ship_mode_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_customer_sk IN (
            SELECT sr_customer_sk 
            FROM store_returns 
            WHERE sr_store_sk = (
                SELECT ss_store_sk FROM store_sales WHERE ss_item_sk = t.ss_item_sk LIMIT 1
            )
        )
    )
ORDER BY 
    t.total_revenue DESC;
