
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk 
        = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
),
AggregatedReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_return_quantity) AS total_return_count,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY wr.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            ELSE 
            CASE 
                WHEN cd.cd_purchase_estimate < 500 THEN 'LOW'
                WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'MEDIUM'
                ELSE 'HIGH'
            END
        END AS purchase_category
    FROM customer_demographics cd
    WHERE cd.cd_gender IS NOT NULL
),
FinalResult AS (
    SELECT 
        cd.cd_gender,
        cd.purchase_category,
        SUM(COALESCE(ar.total_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS total_sales,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM CustomerDemographics cd
    LEFT JOIN AggregatedReturns ar ON cd.cd_demo_sk = ar.wr_returning_customer_sk
    LEFT JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_credit_rating='Fair'
    GROUP BY cd.cd_gender, cd.purchase_category
)
SELECT 
    fr.cd_gender,
    fr.purchase_category,
    fr.total_returns,
    fr.total_sales,
    fr.distinct_items_sold,
    RANK() OVER (ORDER BY fr.total_returns DESC) AS returns_rank
FROM FinalResult fr
WHERE fr.total_returns IS NOT NULL
ORDER BY fr.total_returns DESC
LIMIT 10
UNION
SELECT 
    'TOTAL' AS cd_gender,
    'ALL' AS purchase_category,
    SUM(total_returns),
    SUM(total_sales),
    SUM(distinct_items_sold)
FROM FinalResult
HAVING SUM(total_returns) IS NOT NULL;
