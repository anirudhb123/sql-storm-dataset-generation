
WITH RECURSIVE Sales_Ranking AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450500
),
Customer_Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Total_Sales AS (
    SELECT 
        s.ss_ticket_number,
        SUM(s.ss_ext_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY s.ss_ticket_number
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    SUM(ts.total_sales) AS total_sales,
    AVG(CASE WHEN cd.cd_marital_status IS NULL THEN 0 ELSE cd.cd_purchase_estimate END) AS avg_purchase_estimate,
    COUNT(DISTINCT sr.ws_order_number) AS total_web_orders,
    COUNT(DISTINCT sr.rank) AS unique_ranking
FROM Customer_Demographics cd
JOIN web_sales sr ON cd.c_customer_sk = sr.ws_bill_customer_sk
LEFT JOIN Total_Sales ts ON ts.ss_ticket_number = sr.ws_order_number
JOIN Sales_Ranking r ON sr.ws_order_number = r.ws_order_number AND r.rank <= 5
WHERE cd.cd_gender = 'F'
AND cd.cd_credit_rating IN ('Good', 'Excellent')
GROUP BY c.c_customer_id, cd.cd_gender
HAVING SUM(ts.total_sales) > 5000
ORDER BY total_sales DESC, avg_purchase_estimate DESC
LIMIT 10;
