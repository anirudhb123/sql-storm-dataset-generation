
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_profit,
        RANK() OVER (ORDER BY sales.total_profit DESC) AS item_rank
    FROM 
        SalesSummary sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.total_quantity > (SELECT AVG(total_quantity) FROM SalesSummary)
),
ShippingCosts AS (
    SELECT 
        sm_ship_mode_id,
        SUM(ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        web_sales w
    JOIN 
        ship_mode s ON w.ws_ship_mode_sk = s.sm_ship_mode_sk
    GROUP BY 
        sm_ship_mode_id
)
SELECT 
    CA.ca_city,
    CA.ca_state,
    COUNT(DISTINCT C.c_customer_id) AS customer_count,
    SUM(COALESCE(TotalItems.total_profit, 0)) AS total_profit_from_top_items,
    SUM(COALESCE(ShippingCosts.total_shipping_cost, 0)) AS total_shipping_cost
FROM 
    customer_address CA
LEFT JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
LEFT JOIN 
    TopItems TotalItems ON C.c_current_addr_sk = TotalItems.i_item_id
LEFT JOIN 
    ShippingCosts ON TotalItems.total_quantity > 5
WHERE 
    CA.ca_country = 'USA'
GROUP BY 
    CA.ca_city, CA.ca_state
HAVING 
    COUNT(DISTINCT C.c_customer_id) > 10
ORDER BY 
    total_profit_from_top_items DESC NULLS LAST;
