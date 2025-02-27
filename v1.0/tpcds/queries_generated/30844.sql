
WITH RECURSIVE SalesData AS (
    SELECT 
        w.warehouse_name,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    JOIN 
        warehouse w ON web_sales.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        w.warehouse_name, ws_sold_date_sk
), ProfitableItems AS (
    SELECT 
        item.i_item_id,
        SUM(ws_net_profit) AS item_profit
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    WHERE 
        ws_sold_date_sk IN (SELECT ws_sold_date_sk FROM SalesData WHERE profit_rank <= 10)
    GROUP BY 
        item.i_item_id
)
SELECT 
    ca.city,
    ca.state,
    SUM(sd.total_quantity) AS total_sales,
    AVG(pi.item_profit) AS average_item_profit
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_ship_customer_sk
LEFT JOIN 
    ProfitableItems pi ON sd.warehouse_name = (SELECT w.warehouse_name FROM warehouse w WHERE w.w_warehouse_sk = sd.ws_warehouse_sk)
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(sd.total_quantity) IS NOT NULL
ORDER BY 
    total_sales DESC;
