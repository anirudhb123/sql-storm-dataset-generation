
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(DATEDIFF(DAY, MIN(d.d_date), MAX(d.d_date))) AS avg_days_between_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_country
),
RankedPurchases AS (
    SELECT 
        cp.c_customer_id, 
        cp.total_sales, 
        cp.total_orders, 
        cp.avg_days_between_orders,
        ROW_NUMBER() OVER (ORDER BY cp.total_sales DESC) AS sales_rank
    FROM 
        CustomerPurchases cp
)
SELECT 
    rp.c_customer_id, 
    rp.total_sales, 
    rp.total_orders, 
    rp.avg_days_between_orders,
    ad.ca_country,
    ad.customer_count
FROM 
    RankedPurchases rp
JOIN 
    AddressDetails ad ON rp.c_customer_id = ad.ca_address_id
WHERE 
    rp.sales_rank <= 100
ORDER BY 
    rp.total_sales DESC;
