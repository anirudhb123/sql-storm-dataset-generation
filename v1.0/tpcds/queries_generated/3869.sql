
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws.web_site_id, ws_sold_date_sk
),
ReturnsData AS (
    SELECT 
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        cr_refunded_customer_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY cr_refunded_customer_sk
),
CustomerSummaries AS (
    SELECT 
        cd.cd_gender,
        SUM(cd.cd_dep_count) AS total_dependent_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    sd.web_site_id,
    sd.total_sales_price,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    sd.total_orders,
    sd.avg_profit,
    cs.total_dependent_count,
    cs.avg_purchase_estimate,
    CASE 
        WHEN sd.total_sales_price > 500000 THEN 'High Sales'
        WHEN sd.total_sales_price > 200000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM SalesData sd
LEFT JOIN ReturnsData rd ON sd.ws_sold_date_sk = rd.cr_returned_date_sk
LEFT JOIN CustomerSummaries cs ON cs.total_dependent_count IS NOT NULL
WHERE sales_rank <= 10
ORDER BY sd.total_sales_price DESC;
