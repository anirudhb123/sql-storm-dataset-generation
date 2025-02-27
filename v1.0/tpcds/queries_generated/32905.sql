
WITH RECURSIVE sales_data AS (
    SELECT 
        w.w_warehouse_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, ws.ws_sold_date_sk

    UNION ALL

    SELECT 
        w.w_warehouse_id,
        ws.ws_sold_date_sk,
        sd.total_quantity + SUM(ws.ws_quantity) AS total_quantity,
        sd.total_sales + SUM(ws.ws_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN 
        sales_data sd ON w.w_warehouse_id = sd.w_warehouse_id 
                             AND ws.ws_sold_date_sk = sd.ws_sold_date_sk
    GROUP BY 
        w.w_warehouse_id, ws.ws_sold_date_sk
),

net_profit AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
)

SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    ca.ca_state,
    COALESCE(sd.total_quantity, 0) AS total_web_sales_quantity,
    COALESCE(sd.total_sales, 0) AS total_web_sales,
    COALESCE(np.total_net_profit, 0) AS total_store_net_profit,
    CASE 
        WHEN np.total_sales_count > 0 THEN np.total_net_profit / np.total_sales_count
        ELSE NULL
    END AS avg_net_profit_per_sale
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_data sd ON c.c_first_sales_date_sk = sd.ws_sold_date_sk
LEFT JOIN 
    net_profit np ON c.c_customer_sk = np.ss_store_sk
WHERE 
    (ca.ca_state IS NOT NULL AND ca.ca_state = 'CA') OR 
    (sd.total_sales > 500 OR np.total_net_profit < 0)
ORDER BY 
    c.c_customer_id;
