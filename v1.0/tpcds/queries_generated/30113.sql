
WITH RECURSIVE CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    HAVING SUM(wr_return_quantity) > 5
    
    UNION ALL
    
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
    HAVING SUM(cr_return_quantity) > 5
),
SalesDetails AS (
    SELECT
        ws.web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN Customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY ws.web_site_sk
),
MaxSales AS (
    SELECT
        MAX(total_sales) AS max_sales
    FROM SalesDetails
),
FilteredSales AS (
    SELECT 
        sd.web_site_sk,
        sd.total_sales,
        sd.total_orders
    FROM SalesDetails sd
    JOIN MaxSales ms ON sd.total_sales = ms.max_sales
)
SELECT 
    ca.ca_country,
    COALESCE(SUM(cr.total_return_amount), 0) AS total_catalog_returns,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_returns,
    COUNT(DISTINCT fs.web_site_sk) AS active_web_sites
FROM CustomerReturns cr
FULL OUTER JOIN web_returns wr ON cr.wr_returning_customer_sk = wr.w_returning_customer_sk
JOIN customer_address ca ON cr.wr_returning_addr_sk = ca.ca_address_sk
RIGHT JOIN FilteredSales fs ON fs.web_site_sk = ca.ca_address_sk
WHERE ca.ca_state IN ('CA', 'NY')
GROUP BY ca.ca_country
HAVING AVG(cr.total_returned) > 3 OR AVG(wr.wr_return_quantity) > 10
ORDER BY total_catalog_returns DESC, total_web_returns DESC;
