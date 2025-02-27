
WITH TotalReturns AS (
    SELECT 
        CASE 
            WHEN sr_return_quantity IS NULL THEN 0 
            ELSE SUM(sr_return_quantity) 
        END AS total_returned_qty,
        sr_customer_sk
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
PromotionsUsed AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_promo_sk) AS promo_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cd.c_first_name || ' ' || cd.c_last_name AS customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ts.total_returned_qty,
    ps.promo_count,
    ss.total_web_sales,
    ss.total_store_sales,
    CASE 
        WHEN ss.total_web_sales > ss.total_store_sales THEN 'Web Sales Dominant'
        WHEN ss.total_web_sales < ss.total_store_sales THEN 'Store Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_preference
FROM 
    CustomerDetails cd
LEFT JOIN 
    TotalReturns ts ON cd.c_customer_id = ts.sr_customer_sk
LEFT JOIN 
    PromotionsUsed ps ON cd.c_customer_id = ps.ws_bill_customer_sk
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_id = ss.c_customer_id
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M') 
    AND (ss.total_web_sales + ss.total_store_sales) > 1000
ORDER BY 
    sales_preference, total_web_sales DESC;
