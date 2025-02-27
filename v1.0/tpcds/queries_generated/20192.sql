
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_country IS NOT NULL AND
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
), 
OutlierCustomers AS (
    SELECT 
        rcs.c_customer_id
    FROM 
        RankedCustomerSales rcs
    WHERE 
        rcs.total_sales > (SELECT AVG(total_sales) + 2 * STDDEV(total_sales) FROM RankedCustomerSales)
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS high_value_customers,
    AVG(p.p_cost) AS avg_promotion_cost
FROM 
    customer_address ca
FULL OUTER JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    promotion p ON EXISTS (
        SELECT 1 
        FROM OutlierCustomers oc 
        WHERE oc.c_customer_id = c.c_customer_id
    )
WHERE 
    ca.ca_state = 'CA'
    AND (c.c_customer_id IS NOT NULL OR p.p_promo_id IS NOT NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    high_value_customers DESC
LIMIT 5
OFFSET (SELECT COUNT(*) FROM customer WHERE c_birth_country IS NULL) % 5;
