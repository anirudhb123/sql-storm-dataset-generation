
WITH RECURSIVE recent_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_addr_sk,
        ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY c_birth_year DESC) AS rn
    FROM 
        customer
    WHERE 
        c_birth_year IS NOT NULL
), inventory_summary AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
), store_sales_summary AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales_count
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        recent_customers c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    COALESCE(cts.total_profit, 0) AS total_profit,
    COALESCE(cts.sales_count, 0) AS sales_count,
    ws.ws_name,
    ABS(total_quantity) AS total_inventory_quantity,
    RANK() OVER (ORDER BY COALESCE(cts.total_profit, 0) DESC) AS profit_rank
FROM 
    recent_customers c
LEFT JOIN 
    customer_sales cts ON c.c_customer_sk = cts.c_customer_sk
LEFT JOIN 
    store s ON c.c_current_addr_sk = s.s_store_sk
LEFT JOIN 
    web_site ws ON ws.web_site_sk = c.c_current_addr_sk
LEFT JOIN 
    inventory_summary inv ON inv.inv_item_sk = c.c_current_addr_sk
ORDER BY 
    profit_rank ASC
LIMIT 100;
