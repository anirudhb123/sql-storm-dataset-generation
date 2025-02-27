
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2450000  -- Random threshold for date
),
Aggregated_Sales AS (
    SELECT 
        item.i_item_id,
        SUM(sales.ws_quantity) AS total_quantity,
        SUM(sales.ws_net_profit) AS total_net_profit,
        AVG(sales.ws_sales_price) AS avg_sales_price
    FROM 
        Sales_CTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
),
Customer_Summary AS (
    SELECT 
        ca.city,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(hd.hd_dep_count * 1.0) AS total_dependents
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        ca.city
)
SELECT 
    cs.city,
    cs.total_customers,
    COALESCE(a.total_quantity, 0) AS total_sales_quantity,
    COALESCE(a.total_net_profit, 0) AS total_sales_net_profit,
    COALESCE(a.avg_sales_price, 0) AS average_sales_price,
    STRING_AGG(DISTINCT CONCAT('Item: ', item.i_item_desc, 
                               ' | Net Profit: ', a.total_net_profit, 
                               ' | Quantity: ', a.total_quantity) 
               ORDER BY a.total_quantity DESC) AS item_details
FROM 
    Customer_Summary cs
LEFT JOIN 
    Aggregated_Sales a ON cs.total_customers > 5  -- Sample predicate for join
LEFT JOIN 
    item ON a.i_item_id IS NOT NULL
GROUP BY 
    cs.city, cs.total_customers
ORDER BY 
    cs.total_customers DESC, total_sales_net_profit DESC;
