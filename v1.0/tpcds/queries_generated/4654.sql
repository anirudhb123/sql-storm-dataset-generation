
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
), 
CustomerReturns AS (
    SELECT 
        wr_ret.wr_returning_customer_sk AS customer_sk,
        SUM(wr_ret.wr_return_amt) AS total_returned,
        COUNT(*) AS return_count
    FROM 
        web_returns wr_ret
    GROUP BY 
        wr_ret.wr_returning_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer_demographics cd
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returned, 0) AS total_returned,
    cs.total_sales,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
JOIN 
    RankedSales rs ON c.c_customer_sk = rs.web_site_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    rs.rank_sales <= 10
    AND (cd.cd_purchase_estimate > (SELECT AVG(cd2.cd_purchase_estimate) FROM customer_demographics cd2) OR cd.cd_marital_status = 'M')
ORDER BY 
    total_returned DESC, total_sales DESC;
