
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    ti.i_product_name,
    ti.total_quantity,
    ti.total_profit,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopItems ti
JOIN 
    customer c ON c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk)
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
ORDER BY 
    ti.total_profit DESC;
