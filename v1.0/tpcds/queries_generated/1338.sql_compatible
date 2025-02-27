
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returns
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        wr.returning_customer_sk
),
HighestReturnCustomers AS (
    SELECT 
        cr.returning_customer_sk,
        cr.total_returns,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerReturns cr
    JOIN
        customer_demographics cd ON cr.returning_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_returns > 5
)
SELECT 
    r.website_name,
    SUM(rs.ws_ext_sales_price) AS total_sales,
    SUM(rs.ws_net_profit) AS total_profit,
    COUNT(DISTINCT hrc.returning_customer_sk) AS number_of_high_return_customers
FROM 
    RankedSales rs
JOIN 
    web_site r ON rs.web_site_sk = r.web_site_sk
LEFT JOIN 
    HighestReturnCustomers hrc ON rs.ws_order_number IN (SELECT cr_order_number FROM web_returns WHERE wr_returning_customer_sk = hrc.returning_customer_sk)
GROUP BY 
    r.website_name
HAVING 
    SUM(rs.ws_net_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 10;
