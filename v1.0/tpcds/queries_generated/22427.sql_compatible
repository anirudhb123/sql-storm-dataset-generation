
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
),
DetailedReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    cd.c_last_name,
    cd.c_first_name,
    cd.cd_gender,
    rs.total_sales,
    dr.returns_count,
    dr.total_return_amt,
    dr.total_return_tax,
    CASE 
        WHEN rs.total_sales > 0 AND dr.returns_count IS NULL THEN 'No Returns'
        WHEN dr.returns_count IS NOT NULL AND dr.total_return_amt > 100 THEN 'High Return Amount'
        ELSE 'Normal'
    END AS return_status
FROM 
    RankedSales rs
FULL OUTER JOIN 
    CustomerDetails cd ON rs.web_site_sk = cd.c_customer_sk
LEFT JOIN 
    DetailedReturns dr ON rs.ws_order_number = dr.sr_item_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
    AND (cd.purchase_estimate BETWEEN 100 AND 10000 OR cd.purchase_estimate IS NULL)
ORDER BY 
    COALESCE(rs.total_sales, 0) DESC,
    cd.c_last_name ASC;
