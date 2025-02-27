
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.avg_sales_price,
        sd.total_profit
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 10
), 
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        COUNT( DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_warehouse_sk = s.s_store_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
final_report AS (
    SELECT 
        ss.w_warehouse_id,
        SUM(ts.total_net_profit) AS warehouse_profit,
        COALESCE(MAX(ts.total_quantity), 0) AS max_quantity_sold,
        NULLIF(MIN(ts.avg_sales_price), 0) AS min_avg_price,
        (SELECT COUNT(DISTINCT c.c_customer_sk)
         FROM customer c 
         WHERE c.c_current_addr_sk IS NULL) AS no_address_customers
    FROM 
        sales_summary ss
    LEFT JOIN 
        top_sales ts ON ss.w_warehouse_id = ts.ws_item_sk 
    GROUP BY 
        ss.w_warehouse_id
)
SELECT 
    fr.warehouse_id,
    fr.warehouse_profit,
    fr.max_quantity_sold,
    fr.min_avg_price,
    fr.no_address_customers,
    CASE 
        WHEN fr.warehouse_profit IS NULL THEN 'No Profit Data'
        ELSE 'Profit Data Available' 
    END AS profit_data_status
FROM 
    final_report fr
ORDER BY 
    fr.warehouse_profit DESC;
