
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        p.p_promo_name,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS spending_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, p.p_promo_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_spent,
        cp.orders_count,
        cp.spending_rank
    FROM 
        CustomerPurchases cp
        JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.spending_rank <= 5
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS revenue_rank
    FROM 
        item i
        JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        is.total_quantity_sold,
        is.total_revenue,
        is.revenue_rank
    FROM 
        ItemSales is
    WHERE 
        is.revenue_rank <= 10
),
SalesAnalysis AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        ti.i_item_id,
        ti.total_revenue,
        ti.total_quantity_sold,
        CASE 
            WHEN ti.total_revenue IS NOT NULL THEN ROUND(ti.total_revenue / NULLIF(SUM(tc.total_spent), 0), 2)
            ELSE 0
        END AS revenue_to_spent_ratio
    FROM 
        TopCustomers tc
        CROSS JOIN TopItems ti
    GROUP BY 
        tc.c_first_name, tc.c_last_name, ti.i_item_id, ti.total_revenue, ti.total_quantity_sold
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.i_item_id,
    sa.total_revenue,
    sa.total_quantity_sold,
    sa.revenue_to_spent_ratio,
    CASE 
        WHEN sa.revenue_to_spent_ratio > 1 THEN 'High Value'
        WHEN sa.revenue_to_spent_ratio BETWEEN 0.5 AND 1 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    SalesAnalysis sa
WHERE 
    sa.revenue_to_spent_ratio IS NOT NULL
ORDER BY 
    sa.revenue_to_spent_ratio DESC;
