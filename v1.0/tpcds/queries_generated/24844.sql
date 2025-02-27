
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank,
        CASE 
            WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High Value'
            WHEN SUM(ws.ws_net_profit) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_gender
),
AddressCounts AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        MAX(c.c_birth_year) AS last_customer_birth_year
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_profit, 
        cs.order_count,
        cs.customer_value
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank <= 5 AND cs.customer_value = 'High Value'
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(ac.customer_count, 0) AS address_customer_count,
    hvc.total_profit,
    (SELECT COUNT(*) FROM inventory inv WHERE inv.inv_quantity_on_hand IS NOT NULL) AS total_inventory_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    AddressCounts ac ON hvc.c_customer_sk IN (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = hvc.c_customer_sk)
WHERE 
    hvc.total_profit > (SELECT AVG(total_profit) FROM CustomerSales)
ORDER BY 
    hvc.total_profit DESC
LIMIT 10;
