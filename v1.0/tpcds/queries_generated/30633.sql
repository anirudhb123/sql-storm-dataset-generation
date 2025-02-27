
WITH RECURSIVE CustomerRevenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= 2458594  -- Assuming some date range for analysis
    GROUP BY 
        c.c_customer_sk

    UNION ALL

    SELECT 
        cr.c_customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM 
        CustomerRevenue cr
    JOIN 
        catalog_sales cs ON cr.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cs.cs_sold_date_sk >= 2458594
    GROUP BY 
        cr.c_customer_sk
),
RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_sales, 0) AS total_web_sales,
        COALESCE(cs.total_sales, 0) AS total_catalog_sales,
        (COALESCE(cr.total_sales, 0) + COALESCE(cs.total_sales, 0)) AS total_sales,
        RANK() OVER (ORDER BY (COALESCE(cr.total_sales, 0) + COALESCE(cs.total_sales, 0)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        (SELECT c_customer_sk, SUM(ws_ext_sales_price) AS total_sales
        FROM web_sales
        GROUP BY c_customer_sk) cr ON c.c_customer_sk = cr.c_customer_sk
    LEFT JOIN 
        (SELECT cs_bill_customer_sk AS c_customer_sk, SUM(cs_ext_sales_price) AS total_sales
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk) cs ON c.c_customer_sk = cs.c_customer_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address ca
)
SELECT 
    rc.c_customer_sk,
    rc.total_web_sales,
    rc.total_catalog_sales,
    rc.total_sales,
    ai.ca_city,
    ai.ca_state,
    ai.city_rank
FROM 
    RankedCustomers rc
JOIN 
    customer_address ca ON rc.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressInfo ai ON ca.ca_address_sk = ai.ca_address_sk
WHERE 
    rc.sales_rank <= 10
AND 
    ai.city_rank = 1
ORDER BY 
    rc.total_sales DESC;
