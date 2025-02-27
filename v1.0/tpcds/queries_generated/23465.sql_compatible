
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown' 
            ELSE cd.cd_credit_rating 
        END) AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > (
            SELECT 
                MIN(ws_sold_date_sk) 
            FROM 
                web_sales 
            WHERE 
                ws_sold_date_sk IS NOT NULL
        )
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_ship_customer_sk
),
AggregatedData AS (
    SELECT 
        ci.c_customer_id,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sr.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(sr.total_returns, 0)) AS net_sales,
        COUNT(distinct ci.c_customer_sk) OVER (PARTITION BY ci.cd_gender) AS gender_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_ship_customer_sk
    LEFT JOIN 
        SalesReturns sr ON ci.c_customer_sk = sr.sr_customer_sk
)
SELECT 
    ad.c_customer_id,
    ad.total_sales,
    ad.total_returns,
    ad.net_sales,
    CASE 
        WHEN ad.net_sales > 1000 THEN 'High'
        WHEN ad.net_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ad.gender_count
FROM 
    AggregatedData ad
WHERE 
    ad.net_sales IS NOT NULL
    AND ad.gender_count > (
        SELECT 
            COUNT(*) 
        FROM 
            customer 
        WHERE 
            c_birth_year IS NOT NULL
    ) / 2
ORDER BY 
    ad.net_sales DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
