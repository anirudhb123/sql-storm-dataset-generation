
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        rcs.c_customer_sk,
        rcs.c_first_name,
        rcs.c_last_name,
        rcs.total_sales
    FROM 
        RankedCustomerSales rcs
    WHERE 
        rcs.total_sales > (SELECT AVG(total_sales) FROM RankedCustomerSales)
),
SalesWithAddress AS (
    SELECT 
        hs.c_customer_sk,
        hs.c_first_name,
        hs.c_last_name,
        hs.total_sales,
        ca.ca_city,
        ca.ca_state
    FROM 
        HighSpenders hs
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = hs.c_customer_sk)
)
SELECT 
    swa.c_first_name,
    swa.c_last_name,
    swa.ca_city,
    swa.ca_state,
    COALESCE(swa.total_sales, 0) AS total_sales,
    CASE 
        WHEN swa.total_sales IS NULL THEN 'No Sales'
        ELSE 'High Spender'
    END AS customer_status
FROM 
    SalesWithAddress swa
FULL OUTER JOIN 
    customer c ON swa.c_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year < (EXTRACT(YEAR FROM DATE '2002-10-01') - 30)
ORDER BY 
    total_sales DESC;
