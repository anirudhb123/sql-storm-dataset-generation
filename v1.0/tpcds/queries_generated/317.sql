
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_net_profit,
        cs.total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSales)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(hd.hd_buy_potential, 'Not Specified') AS buy_potential,
    SUM(rs.sr_return_quantity) AS total_returns,
    SUM(ws.ws_net_profit) AS total_spent
FROM 
    HighValueCustomers hvc
JOIN 
    customer c ON hvc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns rs ON c.c_customer_sk = rs.sr_customer_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE 
    hvc.rank = 1
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, hd.hd_buy_potential
HAVING 
    SUM(rs.sr_return_quantity) IS NOT NULL
ORDER BY 
    total_spent DESC
FETCH FIRST 10 ROWS ONLY;
