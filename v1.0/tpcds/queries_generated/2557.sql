
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.order_count > 5
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerDemographics cd ON tc.c_customer_sk = cd.c_customer_sk
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
    AND (tc.total_sales > 1000 OR tc.order_count > 10)
ORDER BY 
    tc.total_sales DESC
LIMIT 100;

SELECT
    'Web Sales' AS source,
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM
    web_sales ws
UNION ALL
SELECT
    'Catalog Sales' AS source,
    SUM(cs.cs_ext_sales_price) AS total_sales
FROM
    catalog_sales cs
UNION ALL
SELECT
    'Store Sales' AS source,
    SUM(ss.ss_ext_sales_price) AS total_sales
FROM
    store_sales ss;

SELECT 
    a.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    a.ca_country = 'USA'
GROUP BY 
    a.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 100
ORDER BY 
    avg_purchase_estimate DESC;
