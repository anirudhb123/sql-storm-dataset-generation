
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_profit) > 0
), 
HighProfitCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        total_profit > (SELECT AVG(total_profit) FROM (SELECT SUM(ws_net_profit) AS total_profit FROM web_sales GROUP BY ws_bill_customer_sk) AS avg_profit)
), 
TopProducts AS (
    SELECT 
        i.i_item_id,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    a.ca_city,
    c.cd_gender,
    hdc.hd_income_band_sk,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY a.ca_city ORDER BY SUM(ws.ws_net_profit) DESC) AS city_rank,
    CASE 
        WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    STRING_AGG(tp.i_item_id, ', ') AS top_items
FROM 
    customer_address a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    household_demographics hdc ON c.c_current_hdemo_sk = hdc.hd_demo_sk
JOIN 
    TopProducts tp ON ws.ws_item_sk = tp.i_item_sk
WHERE 
    c.c_birth_year IS NOT NULL
GROUP BY 
    a.ca_city, c.cd_gender, hdc.hd_income_band_sk
HAVING 
    SUM(ws.ws_net_profit) > 500
ORDER BY 
    total_net_profit DESC;
