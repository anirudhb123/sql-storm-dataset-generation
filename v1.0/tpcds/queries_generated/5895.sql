
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        MAX(ws_net_profit) AS max_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2439 AND 2445  -- Date range for performance benchmarking
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
PopularItems AS (
    SELECT 
        ws_item_sk,
        SUM(total_quantity) AS total_sales_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(total_quantity) DESC) AS sales_rank
    FROM 
        SalesSummary
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(total_quantity) > 1000  -- Filtering for popular items
),
CustomerAnalytics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.c_customer_sk,
    ca.total_orders,
    ca.avg_profit_per_order,
    pi.sales_rank,
    pi.total_sales_quantity
FROM 
    CustomerAnalytics ca
LEFT JOIN 
    PopularItems pi ON pi.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ca.c_customer_sk)
WHERE 
    ca.total_orders > 5  -- Target customers with more than 5 orders
ORDER BY 
    ca.avg_profit_per_order DESC, 
    pi.total_sales_quantity DESC
LIMIT 50;  -- Limit for performance assessment
