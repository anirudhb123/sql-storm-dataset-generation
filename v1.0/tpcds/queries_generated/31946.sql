
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND i.i_current_price > 50.00
    GROUP BY 
        ss.sold_date_sk, ss.ss_item_sk
), 
CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        COUNT(cr.cr_return_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_returning_customer_sk
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
    HAVING 
        SUM(sr.sr_return_quantity) > 5
)

SELECT 
    i.i_item_id,
    COALESCE(SUM(sc.total_quantity), 0) AS sales_quantity,
    COALESCE(SUM(sc.total_sales), 0) AS total_sales,
    COUNT(DISTINCT tc.c_customer_id) AS number_of_returning_customers,
    AVG(tc.total_returns) AS average_returns_per_customer
FROM 
    SalesCTE sc
JOIN 
    item i ON sc.ss_item_sk = i.i_item_sk
LEFT JOIN 
    TopCustomers tc ON tc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sc.ss_item_sk LIMIT 1)
GROUP BY 
    i.i_item_id
ORDER BY 
    total_sales DESC 
LIMIT 10;
