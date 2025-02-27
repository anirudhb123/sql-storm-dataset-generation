
WITH aggregated_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (5, 6) -- May and June
    GROUP BY 
        ws.web_site_sk
),
best_selling_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (5, 6)
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    aa.total_sales,
    aa.total_profit,
    bi.total_quantity_sold,
    bi.total_sales AS item_total_sales
FROM 
    customer_address ca
JOIN 
    aggregated_sales aa ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = aa.web_site_sk)
JOIN 
    best_selling_items bi ON bi.ws_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = aa.web_site_sk LIMIT 1)
ORDER BY 
    aa.total_sales DESC;
