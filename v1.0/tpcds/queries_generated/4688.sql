
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS customer_total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
MaxCustomerProfit AS (
    SELECT 
        MAX(customer_total_profit) AS max_profit
    FROM 
        CustomerSales
),
TopWebsites AS (
    SELECT 
        * 
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    tw.web_name,
    tw.total_quantity,
    tw.total_profit,
    CASE 
        WHEN c.customer_total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    c.customer_total_profit,
    cp.max_profit
FROM 
    TopWebsites tw
LEFT JOIN 
    CustomerSales c ON tw.web_site_sk = c.c_customer_sk
CROSS JOIN 
    MaxCustomerProfit cp
WHERE 
    tw.total_profit > (SELECT AVG(total_profit) FROM RankedSales)
ORDER BY 
    tw.total_profit DESC, tw.total_quantity ASC;
