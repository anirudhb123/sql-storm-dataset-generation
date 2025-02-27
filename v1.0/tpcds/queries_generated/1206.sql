
WITH RankedSales AS (
    SELECT 
        ws.order_number,
        ws.item_sk,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.order_number ORDER BY ws_ext_sales_price DESC) AS rank_sales,
        cd.gender,
        ca.city,
        ca.state,
        CASE 
            WHEN cd.marital_status = 'M' THEN 'Married'
            WHEN cd.marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END AS marital_status_desc
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    JOIN 
        customer_address ca ON c.current_addr_sk = ca.address_sk
    WHERE 
        ws_sales_price > (
            SELECT AVG(ws_sales_price) 
            FROM web_sales 
            WHERE item_sk = ws.item_sk
        )
),
AggregateSales AS (
    SELECT 
        city,
        state,
        COUNT(*) AS total_orders,
        SUM(ws_ext_sales_price) AS total_revenue,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales
    WHERE 
        rank_sales <= 5
    GROUP BY 
        city, state
)
SELECT 
    a.city,
    a.state,
    a.total_orders,
    a.total_revenue,
    COALESCE(a.avg_sales_price, 0) AS avg_sales_price,
    RANK() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank
FROM 
    AggregateSales a
LEFT JOIN 
    warehouse w ON w.warehouse_sk = (SELECT warehouse_sk FROM inventory WHERE item_sk = (SELECT DISTINCT item_sk FROM RankedSales))
WHERE 
    a.total_revenue > 1000
ORDER BY 
    a.total_revenue DESC;
