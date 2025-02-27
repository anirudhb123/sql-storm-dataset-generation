
WITH RECURSIVE customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS web_returned_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(sr.sr_return_quantity) DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
aggregate_data AS (
    SELECT 
        SUM(total_returns) AS total_returns_sum,
        AVG(cd_purchase_estimate) AS average_estimate
    FROM customer_analysis
    WHERE rn = 1
),
item_performance AS (
    SELECT 
        i.i_item_sk, 
        COUNT(ws.ws_order_number) AS web_sales_count, 
        COUNT(cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ca.c_email_address,
    ca.cd_gender,
    ca.cd_marital_status,
    ad.total_returns_sum,
    ad.average_estimate,
    ip.i_item_sk,
    ip.web_sales_count,
    ip.catalog_sales_count,
    ip.total_store_returns,
    ip.total_catalog_returns,
    CASE 
        WHEN (ip.web_sales_count + ip.catalog_sales_count) = 0 THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM customer_analysis ca
JOIN aggregate_data ad ON ca.rn = 1
LEFT JOIN item_performance ip ON ca.c_customer_sk = ip.i_item_sk
WHERE (ad.average_estimate IS NOT NULL OR ad.total_returns_sum > 0)
AND (ca.cd_gender = 'M' OR ca.cd_marital_status = 'M')
ORDER BY ca.c_last_name ASC, ca.c_first_name ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
