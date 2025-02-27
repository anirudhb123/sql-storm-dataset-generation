
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COALESCE(SUM(cr.cr_return_amt), 0) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
AggDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        COUNT(cd.cd_demo_sk) AS total_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
),
SelectedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ad.total_returned,
        ad.return_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY ad.total_returned DESC) AS return_rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns ad ON c.c_customer_sk = ad.returning_customer_sk
    LEFT JOIN 
        AggDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS customer_full_name,
    COALESCE(r.rank, 0) AS rank_sales,
    ROUND(a.avg_purchase_estimate, 2) AS avg_purchase_estimate,
    CASE 
        WHEN c.cd_gender = 'M' THEN 'Male'
        WHEN c.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    CASE 
        WHEN r.rank <= 3 THEN 'Top Sales'
        ELSE 'Regular Sales'
    END AS sales_performance
FROM 
    SelectedCustomers c
FULL OUTER JOIN 
    RankedSales r ON c.c_customer_sk = r.ws_item_sk
FULL JOIN 
    AggDemographics a ON c.cd_demo_sk = a.cd_demo_sk
WHERE 
    c.return_count IS NULL OR c.return_count > 0
ORDER BY 
    sales_performance DESC, customer_full_name;
