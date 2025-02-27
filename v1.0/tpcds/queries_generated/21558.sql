
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'UNKNOWN' 
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
MonthlyReturns AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS return_year,
        EXTRACT(MONTH FROM d.d_date) AS return_month,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY 
        return_year, return_month
),
FilteredReturns AS (
    SELECT 
        return_year,
        return_month,
        total_returns,
        RANK() OVER (ORDER BY total_returns DESC) AS return_rank
    FROM 
        MonthlyReturns
    WHERE 
        total_returns > 10
)
SELECT 
    cd.cd_gender,
    cd.marital_status,
    cd.credit_rating,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    COALESCE(SUM(fs.ws_sales_price), 0) AS total_sales,
    COALESCE(SUM(fr.total_returns), 0) AS total_returns
FROM 
    CustomerDemographics cd
LEFT JOIN 
    web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
LEFT JOIN 
    RankedSales rs ON ws.ws_order_number = rs.ws_order_number
LEFT JOIN 
    FilteredReturns fr ON fr.return_year = EXTRACT(YEAR FROM ws.ws_sold_date_sk) 
                        AND fr.return_month = EXTRACT(MONTH FROM ws.ws_sold_date_sk)
LEFT JOIN 
    catalog_sales cs ON cs.cs_order_number = ws.ws_order_number
WHERE 
    (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.credit_rating
HAVING 
    COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY 
    total_sales DESC
LIMIT 100;
