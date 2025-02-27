
WITH RECURSIVE CustomerReturnCTE AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        SUM(sr_return_amount) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_customer_sk
    UNION ALL
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        total_return_amount + COALESCE((SELECT SUM(sr_return_amount)
                                         FROM store_returns sr2
                                         WHERE sr2.sr_customer_sk = sr1.sr_customer_sk
                                         AND sr2.sr_returned_date_sk < sr1.sr_returned_date_sk), 0)
    FROM 
        store_returns sr1
    INNER JOIN 
        CustomerReturnCTE cte ON sr1.sr_customer_sk = cte.sr_customer_sk
),
MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd_cd_demo_sk,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
)
SELECT 
    ca.ca_city,
    SUM(COALESCE(cr.total_return_amount, 0)) AS total_return_amount,
    md.total_sales,
    md.total_discount,
    cd.female_count,
    cd.male_count
FROM 
    customer_address ca
LEFT JOIN 
    CustomerReturnCTE cr ON ca.ca_address_sk = cr.sr_customer_sk
JOIN 
    MonthlySales md ON ca.ca_address_sk = md.d_year 
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = cr.sr_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND (md.total_sales - md.total_discount) > 1000
GROUP BY 
    ca.ca_city, md.total_sales, md.total_discount, cd.female_count, cd.male_count
ORDER BY 
    total_return_amount DESC, total_sales DESC
FETCH FIRST 10 ROWS ONLY;
