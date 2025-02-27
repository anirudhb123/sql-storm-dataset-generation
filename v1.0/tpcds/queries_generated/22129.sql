
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(CASE WHEN cd.cd_gender = 'F' THEN 1 END) AS female_count,
        COUNT(CASE WHEN cd.cd_gender = 'M' THEN 1 END) AS male_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
RankedSales AS (
    SELECT 
        c_customer_id, 
        total_net_profit,
        order_count,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY order_count DESC) AS order_rank
    FROM 
        CustomerSales
),
SalesSummary AS (
    SELECT 
        profit_rank,
        AVG(total_net_profit) AS avg_net_profit,
        MAX(order_count) AS max_orders,
        MIN(CASE WHEN order_count > 0 THEN order_count ELSE NULL END) AS min_non_zero_orders
    FROM 
        RankedSales
    GROUP BY 
        profit_rank
)
SELECT 
    ss.profit_rank,
    ss.avg_net_profit,
    ss.max_orders,
    ss.min_non_zero_orders,
    (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales) AS total_items_sold,
    (SELECT COUNT(DISTINCT c_customer_sk) FROM customer WHERE c_preferred_cust_flag = 'Y') AS preferred_customers,
    CASE 
        WHEN ss.avg_net_profit IS NULL THEN 'No Sales' 
        WHEN ss.avg_net_profit = 0 THEN 'Break-even' 
        ELSE 'Profitable' 
    END AS profitability_status
FROM 
    SalesSummary ss
LEFT JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT TOP 1 w_warehouse_sk FROM warehouse ORDER BY NEWID()) -- Simulating selection from a random warehouse
WHERE 
    ss.profit_rank IS NOT NULL AND ss.profit_rank <= 10
ORDER BY 
    ss.profit_rank;
