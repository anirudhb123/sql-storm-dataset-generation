
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk BETWEEN 2458480 AND 2458487
    GROUP BY 
        ws.web_site_sk
), MaxProfit AS (
    SELECT 
        web_site_sk,
        MAX(total_net_profit) AS max_profit
    FROM 
        SalesCTE
    GROUP BY 
        web_site_sk
), AddressInfo AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.ca_state IS NOT NULL
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
    HAVING 
        COUNT(c.c_customer_sk) > 5
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.customer_count,
    s.web_site_sk,
    s.total_net_profit,
    s.total_orders
FROM 
    AddressInfo a
JOIN 
    SalesCTE s ON s.web_site_sk IN (SELECT web_site_sk FROM MaxProfit WHERE max_profit > 10000)
ORDER BY 
    a.customer_count DESC, 
    s.total_net_profit DESC;
