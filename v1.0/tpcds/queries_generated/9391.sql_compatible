
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        sd.ss_store_sk,
        cs.cs_item_sk,
        cs.cs_net_profit AS catalog_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales sd ON ws.ws_item_sk = sd.ss_item_sk AND ws.ws_order_number = sd.ss_ticket_number
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        sd.ss_store_sk, 
        cs.cs_item_sk
), CategoryProfit AS (
    SELECT 
        i.i_category,
        SUM(sd.total_profit) AS total_category_profit,
        SUM(sd.total_quantity) AS total_category_quantity
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
), AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses, 
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address 
    GROUP BY 
        ca_state
)
SELECT
    cp.i_category,
    cp.total_category_profit,
    cp.total_category_quantity,
    as.avg_gmt_offset,
    as.unique_addresses
FROM 
    CategoryProfit cp
JOIN 
    AddressStats as ON cp.total_category_quantity > 100
ORDER BY 
    cp.total_category_profit DESC
LIMIT 10;
