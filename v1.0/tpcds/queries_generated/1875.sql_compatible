
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
FilteredStats AS (
    SELECT 
        gender,
        total_spent,
        total_orders,
        avg_order_value,
        NTILE(4) OVER (ORDER BY total_spent DESC) AS expenditure_band
    FROM 
        CustomerStats
    WHERE 
        total_spent IS NOT NULL
),
TopExpenders AS (
    SELECT 
        gender,
        total_spent,
        total_orders,
        avg_order_value,
        expenditure_band
    FROM 
        FilteredStats
    WHERE 
        expenditure_band = 1
)
SELECT 
    te.gender,
    te.total_spent,
    te.total_orders,
    te.avg_order_value,
    ps.promo_name
FROM 
    TopExpenders te
LEFT JOIN 
    promotion ps ON te.total_spent > ps.p_cost
WHERE 
    te.total_orders > (
        SELECT AVG(total_orders) 
        FROM FilteredStats
        WHERE gender = te.gender
    )
ORDER BY 
    te.total_spent DESC;
