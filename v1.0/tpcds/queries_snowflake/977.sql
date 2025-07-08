
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
)
SELECT 
    ca.ca_address_id,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customers,
    SUM(CASE WHEN c.c_birth_country IS NULL THEN 1 ELSE 0 END) AS null_birth_country_count
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM RankedSales r
        WHERE r.ws_item_sk = cs.cs_item_sk
        AND r.rank_profit <= 5
    )
GROUP BY 
    ca.ca_address_id
ORDER BY 
    total_catalog_sales DESC
LIMIT 10;
