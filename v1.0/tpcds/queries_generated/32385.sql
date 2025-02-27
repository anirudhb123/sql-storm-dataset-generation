
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_category, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 5
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(sr_return_quantity) AS total_returns,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_returns,
    cr.total_return_amount,
    ss.total_sales,
    ss.order_count,
    CONCAT('Income Group: ', CASE 
        WHEN cd.cd_purchase_estimate < 50000 THEN 'Low'
        WHEN cd.cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'High' END
    ) AS income_group,
    ih.i_item_desc,
    ih.i_brand,
    ih.i_category
FROM CustomerReturns cr
LEFT JOIN CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk
LEFT JOIN SalesSummary ss ON cr.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN ItemHierarchy ih ON ih.i_item_desc LIKE '%' || cr.c_last_name || '%'
WHERE cr.total_returns > 0
AND ss.sales_rank <= 10
ORDER BY cr.total_return_amount DESC, ss.total_sales DESC;
