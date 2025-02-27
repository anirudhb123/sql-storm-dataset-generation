
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cs.total_returns, 0) AS returns,
    COALESCE(rs.total_sales, 0) AS sales,
    CASE 
        WHEN COALESCE(cs.total_returns, 0) > 0 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM 
    CustomerDetails cd
LEFT JOIN 
    CustomerReturns cs ON cd.c_customer_sk = cs.wr_returning_customer_sk
LEFT JOIN 
    RankedSales rs ON cd.c_customer_sk = rs.web_site_sk
WHERE 
    cd.gender_rank = 1
    AND (cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 1000)
ORDER BY 
    risk_category DESC, 
    sales DESC;
