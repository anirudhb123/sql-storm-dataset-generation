
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
),
HighValueSales AS (
    SELECT 
        web_site_sk, 
        ws_order_number, 
        ws_ext_sales_price 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
),
SalesStats AS (
    SELECT 
        hs.web_site_sk,
        COUNT(hs.ws_order_number) AS total_orders,
        SUM(hs.ws_ext_sales_price) AS total_sales,
        AVG(hs.ws_ext_sales_price) AS avg_sale
    FROM 
        HighValueSales hs 
    GROUP BY 
        hs.web_site_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.avg_sale, 0) AS avg_sale,
    a.customer_count
FROM 
    AddressInfo a 
FULL OUTER JOIN 
    SalesStats ss ON a.ca_address_sk = ss.web_site_sk
WHERE 
    (a.ca_state IS NOT NULL OR ss.total_orders IS NOT NULL)
    AND (a.customer_count > 5 OR ss.total_sales > 1000)
ORDER BY 
    a.ca_city ASC, 
    total_sales DESC;
