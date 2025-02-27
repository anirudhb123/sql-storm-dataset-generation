
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c_customer_id,
        total_profit,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM 
        CustomerSales
    WHERE 
        total_profit > (SELECT AVG(total_profit) FROM CustomerSales)
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    hvc.c_customer_id,
    hvc.total_profit,
    hvc.total_orders,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    ca.customer_count,
    CASE 
        WHEN hvc.rank <= 10 THEN 'Top 10%'
        WHEN hvc.rank <= 50 THEN 'Top 50%'
        ELSE 'Others'
    END AS customer_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerAddresses ca ON hvc.c_customer_id = (
        SELECT 
            c.c_customer_id 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_id = hvc.c_customer_id)
    )
WHERE 
    (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL OR ca.ca_country IS NOT NULL)
ORDER BY 
    hvc.total_profit DESC;
