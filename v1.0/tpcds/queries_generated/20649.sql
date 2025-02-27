
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CROSSES
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_first_name LIKE 'A%')
),
AggregatedSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_revenue,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank <= 5 -- only top 5 prices
    GROUP BY 
        rs.ws_item_sk
),
TopItems AS (
    SELECT 
        a.ws_item_sk,
        a.total_revenue,
        a.total_orders,
        RANK() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank
    FROM 
        AggregatedSales a
)
SELECT 
    ti.ws_item_sk,
    ti.total_revenue,
    ti.total_orders,
    CASE 
        WHEN ti.revenue_rank = 1 THEN 'Top Seller'
        WHEN ti.revenue_rank <= 5 THEN 'High Seller'
        ELSE 'Regular Seller'
    END AS seller_category,
    COALESCE((SELECT COUNT(DISTINCT sr.store_sk) 
              FROM store_returns sr 
              WHERE sr.sr_item_sk = ti.ws_item_sk 
              AND sr.sr_return_quantity > 0), 0) AS total_returns
FROM 
    TopItems ti
WHERE 
    ti.total_orders > 10
ORDER BY 
    ti.total_revenue DESC
LIMIT 10
UNION ALL
SELECT 
    'Total' AS ws_item_sk,
    SUM(total_revenue) AS total_revenue, 
    SUM(total_orders) AS total_orders, 
    'Aggregated' AS seller_category,
    SUM(total_returns) AS total_returns
FROM (
    SELECT 
        SUM(a.total_revenue) AS total_revenue,
        SUM(a.total_orders) AS total_orders,
        COALESCE((SELECT SUM(sr.return_quantity) 
                  FROM store_returns sr 
                  WHERE sr_item_sk = a.ws_item_sk), 0) AS total_returns
    FROM 
        AggregatedSales a
    GROUP BY 
        a.ws_item_sk
) AS overall_totals;
