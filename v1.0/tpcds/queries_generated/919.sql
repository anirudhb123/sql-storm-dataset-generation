
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr_return_amt_inc_tax, 0) + COALESCE(cr_return_amt_inc_tax, 0) + COALESCE(wr_return_amt_inc_tax, 0)) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS store_returns_count,
        COUNT(DISTINCT cr_order_number) AS catalog_returns_count,
        COUNT(DISTINCT wr_order_number) AS web_returns_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Regular Value'
        END AS customer_value_segment
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
PopularItems AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sold,
        ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_quantity) DESC) AS item_rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    GROUP BY cs.cs_item_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT cr.c_customer_id) AS customers_returned,
    SUM(cr.total_returned_quantity) AS total_quantity_returned,
    SUM(cr.total_returned_amount) AS total_amount_returned,
    pi.total_sold AS popular_item_sales,
    pi.item_rank
FROM CustomerReturns cr
JOIN CustomerDemographics cd ON cr.c_customer_id = cd.cd_demo_sk
LEFT JOIN PopularItems pi ON pi.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'FURNITURE')
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, pi.total_sold, pi.item_rank
HAVING COUNT(DISTINCT cr.c_customer_id) > 10
ORDER BY total_amount_returned DESC;
