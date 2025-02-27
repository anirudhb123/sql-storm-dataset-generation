
WITH recent_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        MAX(DATEADD(day, d.d_date_sk, '1970-01-01')) AS latest_sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_revenue,
        RANK() OVER (ORDER BY rs.total_revenue DESC) AS revenue_rank
    FROM 
        recent_sales rs
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_revenue,
    ti.revenue_rank,
    cd.cd_gender,
    pd.p_discount_active
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk
        FROM web_sales ws
        WHERE ws.ws_item_sk = ti.ws_item_sk
    )
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    promotion pd ON i.i_item_sk = pd.p_item_sk 
WHERE 
    ti.revenue_rank <= 10
ORDER BY 
    ti.total_revenue DESC;
