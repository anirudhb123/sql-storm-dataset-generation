
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_quantity DESC) AS rank_qty,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rank_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2023-01-01')
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
StoreSummary AS (
    SELECT 
        s_store_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
ShippingDetails AS (
    SELECT 
        sm_ship_mode_id,
        SUM(ws_ext_ship_cost) AS total_shipping_cost,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    JOIN 
        ship_mode ON ws_ship_mode_sk = sm_ship_mode_sk
    GROUP BY 
        sm_ship_mode_id
)
SELECT 
    ca.city AS customer_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(c.total_return_amt) AS avg_return_amt,
    sd.total_shipping_cost,
    ss.total_sales AS total_store_sales,
    ss.total_net_profit
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    StoreSummary ss ON ws.ws_warehouse_sk = ss.s_store_sk
JOIN 
    ShippingDetails sd ON sd.sm_ship_mode_id = ws.ws_ship_mode_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    ws.ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 5)
    AND (cr.total_return_qty IS NULL OR cr.total_return_qty < 5)
GROUP BY 
    ca.city, sd.total_shipping_cost, ss.total_sales, ss.total_net_profit
HAVING 
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY 
    total_sales DESC;
