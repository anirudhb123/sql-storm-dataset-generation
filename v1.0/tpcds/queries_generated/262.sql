
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
), HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales,
        cs.order_count,
        cs.item_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
), TempSummary AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_sales,
        hvc.order_count,
        hvc.item_count,
        CASE 
            WHEN hvc.total_sales > 5000 THEN 'Platinum'
            WHEN hvc.total_sales > 2500 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_tier
    FROM 
        HighValueCustomers hvc
)

SELECT 
    ca.ca_address_id, 
    ca.ca_city, 
    ca.ca_state, 
    ts.total_sales, 
    ts.order_count, 
    ts.item_count, 
    ts.customer_tier
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    TempSummary ts ON c.c_customer_sk = ts.c_customer_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    ts.total_sales DESC
LIMIT 10
UNION 
SELECT 
    NULL AS ca_address_id, 
    NULL AS ca_city, 
    NULL AS ca_state, 
    AVG(total_sales) AS average_sales, 
    NULL AS order_count, 
    NULL AS item_count, 
    'National Average' AS customer_tier
FROM 
    TempSummary
WHERE 
    total_sales IS NOT NULL;
