
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
SalesDetails AS (
    SELECT 
        CASE 
            WHEN ws_sales_price IS NOT NULL THEN 'Web Sale'
            WHEN cs_sales_price IS NOT NULL THEN 'Catalog Sale'
            WHEN ss_sales_price IS NOT NULL THEN 'Store Sale'
        END AS SaleType,
        COALESCE(ws_sales_price, cs_sales_price, ss_sales_price) AS SalePrice,
        COALESCE(ws_ship_mode_sk, cs_ship_mode_sk, ss_promo_sk) AS PromoType
    FROM 
        web_sales ws 
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number 
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ad.FullAddress,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        sd.SaleType,
        sd.SalePrice
    FROM 
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN AddressDetails ad ON ad.FullAddress = CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)
    JOIN SalesDetails sd ON c.c_customer_sk = sd.ws_bill_customer_sk OR c.c_customer_sk = sd.cs_bill_customer_sk OR c.c_customer_sk = sd.ss_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.FullAddress,
    cs.ca_city,
    cs.ca_state,
    cs.ca_zip,
    COUNT(cs.SaleType) AS TotalSales,
    AVG(cs.SalePrice) AS AverageSalePrice
FROM 
    CustomerSales cs
GROUP BY 
    cs.c_customer_id, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.FullAddress, 
    cs.ca_city, 
    cs.ca_state, 
    cs.ca_zip
HAVING 
    COUNT(cs.SaleType) > 0
ORDER BY 
    TotalSales DESC;
