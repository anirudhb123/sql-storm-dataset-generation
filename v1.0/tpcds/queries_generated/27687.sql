
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city) AS full_address
    FROM 
        customer_address
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        AddressComponents addr ON ws.ws_bill_addr_sk = addr.ca_address_sk
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.ws_order_number,
    r.total_quantity,
    r.total_sales,
    addr.full_address
FROM 
    RankedSales r
JOIN 
    AddressComponents addr ON r.ws_order_number = addr.ca_address_sk
WHERE 
    r.sales_rank = 1
ORDER BY 
    r.total_sales DESC;
