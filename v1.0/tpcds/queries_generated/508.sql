
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, credit_rating
),
HighValueReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amt,
        COUNT(cr.cr_return_quantity) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
    HAVING 
        SUM(cr.cr_return_amount) > 1000
)
SELECT 
    ca.ca_city,
    SUM(COALESCE(ahs.ws_net_paid, 0)) AS total_sales,
    SUM(COALESCE(hvr.total_return_amt, 0)) AS total_returns,
    DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ahs.ws_net_paid, 0)) DESC) AS sales_rank
FROM 
    customer_address ca
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk 
LEFT JOIN 
    RankedSales ahs ON ws.ws_web_site_sk = ahs.web_site_sk
LEFT JOIN 
    HighValueReturns hvr ON ws.ws_item_sk = hvr.cr_item_sk
JOIN 
    CustomerDemographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
GROUP BY 
    ca.ca_city
HAVING 
    SUM(COALESCE(ahs.ws_net_paid, 0)) > 5000
ORDER BY 
    sales_rank
FETCH FIRST 10 ROWS ONLY;
