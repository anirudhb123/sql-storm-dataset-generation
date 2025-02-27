
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_moy BETWEEN 6 AND 8
        )
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ri.i_item_id,
        rs.total_sold,
        rs.avg_sales_price,
        rs.total_revenue,
        RANK() OVER (ORDER BY rs.total_revenue DESC) AS revenue_rank
    FROM 
        RecentSales rs
    JOIN 
        item ri ON rs.ws_item_sk = ri.i_item_sk
    WHERE 
        rs.total_sold > 100
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_paid_inc_ship_tax) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2022
        )
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.net_paid_inc_ship_tax) > 1000
)
SELECT 
    t.i_item_id,
    t.total_sold,
    t.avg_sales_price,
    t.total_revenue,
    h.c_customer_id,
    h.total_spent
FROM 
    TopItems t
LEFT JOIN 
    HighValueCustomers h ON t.revenue_rank <= 10
ORDER BY 
    t.total_revenue DESC, h.total_spent DESC;
