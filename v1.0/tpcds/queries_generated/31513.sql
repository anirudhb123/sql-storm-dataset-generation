
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_sk,
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY DATE(d.d_date) DESC) AS daily_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_sk, d.d_date
),
TopSales AS (
    SELECT 
        web_site_sk,
        sale_date,
        total_sales
    FROM 
        SalesData
    WHERE 
        daily_rank <= 7
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COALESCE(SUM(wr_return_amt), 0) AS total_return,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(ts.total_sales, 0) AS last_week_sales,
    cr.total_return AS total_returns,
    (CASE 
        WHEN cr.return_count > 0 THEN 
            (cr.total_return / (ts.total_sales + NULLIF(ts.total_sales, 0))) * 100 
        ELSE 0 END) AS return_percentage,
    (SELECT COUNT(*) 
     FROM customer c2 
     WHERE c2.c_birth_year = cs.c_birth_year) AS same_age_count
FROM 
    customer_address ca
JOIN 
    customer cs ON ca.ca_address_sk = cs.c_current_addr_sk
LEFT JOIN 
    TopSales ts ON ts.web_site_sk = cs.c_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returning_customer_sk = cs.c_customer_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    return_percentage DESC
LIMIT 100;
