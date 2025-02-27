
WITH RECURSIVE MonthSales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
    UNION ALL
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        MonthSales ms ON d.d_date > ms.d_date
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
),
TopItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_net_profit) AS total_store_profit,
    COALESCE(ms.total_web_profit, 0) AS online_profit,
    COUNT(ct.c_customer_sk) AS returning_customers
FROM 
    customer_address ca
JOIN 
    store s ON ca.ca_address_sk = s.s_closed_date_sk
LEFT JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    customer ct ON ss.ss_customer_sk = ct.c_customer_sk
LEFT JOIN 
    MonthSales ms ON EXTRACT(MONTH FROM ms.d_date) = EXTRACT(MONTH FROM CURRENT_DATE)
WHERE 
    ca.ca_state IN ('NY', 'CA')
    AND ss.ss_sales_price < 100
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_net_profit) > 5000
    OR COUNT(ct.c_customer_sk) > 10
ORDER BY 
    total_store_profit DESC, online_profit DESC;
