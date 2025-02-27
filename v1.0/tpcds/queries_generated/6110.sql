
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.profit_rank <= 10
),
BestCustomer AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 1
),
SalesByCity AS (
    SELECT 
        ca.ca_city,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_net_profit,
    bc.c_customer_id AS best_customer_id,
    sbc.ca_city,
    sbc.total_sales
FROM 
    TopSellingItems tsi,
    BestCustomer bc,
    SalesByCity sbc
ORDER BY 
    tsi.total_net_profit DESC, 
    sbc.total_sales DESC;
