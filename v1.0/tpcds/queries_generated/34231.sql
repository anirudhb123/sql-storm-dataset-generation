
WITH RECURSIVE sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales_count
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
    HAVING 
        SUM(ss_net_profit) > 0

    UNION ALL

    SELECT 
        inventory.inv_warehouse_sk AS s_store_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(cs_order_number) AS total_sales_count
    FROM 
        catalog_sales cs
    JOIN 
        inventory ON cs.cs_item_sk = inventory.inv_item_sk
    GROUP BY 
        inventory.inv_warehouse_sk
    HAVING 
        SUM(cs_net_profit) > 0
), filtered_sales AS (
    SELECT 
        s_store_sk,
        total_net_profit,
        total_sales_count,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        sales_summary
)
SELECT 
    fa.ca_city,
    fa.ca_state,
    COALESCE(fs.total_net_profit, 0) AS total_net_profit,
    fs.total_sales_count,
    fa.ca_address_id,
    ROW_NUMBER() OVER (PARTITION BY fa.ca_state ORDER BY fs.total_net_profit DESC) AS state_rank
FROM 
    customer_address fa
LEFT JOIN 
    filtered_sales fs ON fa.ca_address_sk = fs.s_store_sk
WHERE 
    fa.ca_city IS NOT NULL
    AND (fs.total_sales_count > 10 OR fs.total_net_profit IS NULL)
ORDER BY 
    fa.ca_state, fs.total_net_profit DESC
LIMIT 100;
