
WITH RankedReturns AS (
    SELECT 
        CASE 
            WHEN wr.returning_customer_sk IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS returner_type,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_value,
        RANK() OVER (PARTITION BY wr_item_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS return_rank
    FROM web_returns wr
    GROUP BY 
        wr.returning_customer_sk, 
        wr_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COALESCE(hd.hd_dep_count, 0) AS dependency_count
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
SalesAggregates AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COALESCE(GLB.top_category, 'Miscellaneous') AS category
    FROM web_sales ws
    LEFT JOIN (
        SELECT 
            i.i_item_sk,
            i.i_category_id,
            ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
        FROM item i
        JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
        GROUP BY i.i_item_sk, i.i_category_id
    ) AS GLB ON ws.ws_item_sk = GLB.i_item_sk AND GLB.rn = 1
    GROUP BY ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    sr.total_returned,
    sr.total_return_value,
    sa.total_sold,
    sa.total_sales_value,
    sa.distinct_orders,
    CASE 
        WHEN sr.return_rank = 1 AND sa.total_sold > 0 THEN 'Top Returner'
        WHEN sr.return_rank > 1 AND sa.total_sold > 0 THEN 'Frequent Returner'
        ELSE 'No Returns'
    END AS returner_category
FROM customer c
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN RankedReturns sr ON c.c_customer_sk = sr.returning_customer_sk
LEFT JOIN SalesAggregates sa ON sr.wr_item_sk = sa.ws_item_sk
WHERE 
    sr.total_returned IS NOT NULL OR sa.total_sold > 0
ORDER BY 
    cd.cd_marital_status NULLS LAST, 
    sa.total_sales_value DESC;
