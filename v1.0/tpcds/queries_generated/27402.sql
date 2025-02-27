
WITH 
    AddressData AS (
        SELECT 
            ca.city AS city, 
            ca.state AS state,
            COUNT(DISTINCT c.c_customer_id) AS customer_count,
            AVG(cd.purchase_estimate) AS avg_purchase_estimate
        FROM 
            customer_address ca
        JOIN 
            customer c ON ca.ca_address_sk = c.c_current_addr_sk
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY 
            ca.city, ca.state
    ),
    SalesData AS (
        SELECT 
            s.s_store_name AS store_name, 
            COUNT(DISTINCT ws.ws_order_number) AS total_orders,
            SUM(ws.ws_net_profit) AS total_profit
        FROM 
            store s
        JOIN 
            web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
        GROUP BY 
            s.s_store_name
    )
SELECT 
    ad.city, 
    ad.state, 
    ad.customer_count, 
    ad.avg_purchase_estimate, 
    sd.store_name, 
    sd.total_orders, 
    sd.total_profit
FROM 
    AddressData ad
JOIN 
    SalesData sd ON ad.city = 'New York' AND ad.state = 'NY' 
ORDER BY 
    ad.customer_count DESC, sd.total_profit DESC;
