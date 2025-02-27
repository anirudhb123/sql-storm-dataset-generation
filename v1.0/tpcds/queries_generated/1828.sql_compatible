
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_state) AS city_rank
    FROM 
        customer_address ca
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_sales,
        ai.ca_city,
        ai.ca_state
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
    WHERE 
        cp.total_sales > (
            SELECT AVG(total_sales) 
            FROM CustomerPurchases 
            WHERE total_orders > 1
        )
)
SELECT 
    hv.c_customer_sk,
    hv.total_sales,
    hv.ca_city,
    hv.ca_state
FROM 
    HighValueCustomers hv
FULL OUTER JOIN 
    store s ON hv.total_sales > s.s_net_profit
WHERE 
    hv.ca_city IS NOT NULL OR s.s_store_name IS NOT NULL
ORDER BY 
    hv.total_sales DESC, 
    COALESCE(s.s_net_profit, 0) ASC;
