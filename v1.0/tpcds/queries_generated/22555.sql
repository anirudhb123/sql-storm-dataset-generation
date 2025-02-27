
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
),
AggregateReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd_credit_rating) AS min_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
DailySales AS (
    SELECT 
        d_date,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS unique_orders,
        SUM(ws_ext_tax) AS total_tax
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_date
),
SalesWithReturns AS (
    SELECT 
        ds.d_date,
        ds.total_sales,
        COALESCE(ar.total_returns, 0) AS total_returns,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount,
        (ds.total_sales - COALESCE(ar.total_return_amount, 0)) AS net_sales
    FROM 
        DailySales ds
    LEFT JOIN 
        AggregateReturns ar ON ds.d_date = (SELECT d_date FROM date_dim WHERE d_date_sk = (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date < ds.d_date))
)

SELECT
    ds.d_date,
    ds.total_sales,
    ds.total_returns,
    ds.total_return_amount,
    ds.net_sales,
    cd.gender AS demographic_gender,
    cd.customer_count,
    cd.avg_purchase_estimate,
    cd.min_credit_rating,
    rs.ws_sales_price AS highest_sales_price
FROM 
    SalesWithReturns ds
JOIN 
    CustomerDemographics cd ON (cd.customer_count IS NOT NULL OR cd.customer_count IS NOT NULL)
LEFT OUTER JOIN 
    RankedSales rs ON ds.d_date = (SELECT d_date FROM date_dim WHERE d_date_sk = (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date < CURRENT_DATE)) 
WHERE 
    (ds.total_sales > 1000 AND ds.total_returns IS NOT NULL)
    OR (ds.total_returns = 0 AND ds.total_sales < 5000)
ORDER BY 
    ds.d_date DESC, 
    cd.gender
LIMIT 50
OFFSET 10;
