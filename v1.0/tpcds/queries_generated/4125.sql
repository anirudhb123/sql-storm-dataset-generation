
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(COALESCE(ws.net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS total_ship_modes
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY 
        i.i_item_sk
),
TopSellingItems AS (
    SELECT 
        is.i_item_id,
        is.total_sales,
        is.total_orders,
        is.avg_net_profit,
        is.total_ship_modes
    FROM 
        ItemSummary is
    WHERE 
        is.total_sales > 1000
    ORDER BY 
        is.total_sales DESC
    LIMIT 10
)
SELECT 
    ca.ca_city,
    SUM(ts.total_sales) AS city_sales,
    COUNT(ts.i_item_id) AS items_sold,
    MAX(ts.avg_net_profit) AS max_avg_profit
FROM 
    TopSellingItems ts
JOIN 
    customer c ON ts.i_item_id = c.c_customer_id
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    city_sales DESC
FETCH FIRST 5 ROWS ONLY;
