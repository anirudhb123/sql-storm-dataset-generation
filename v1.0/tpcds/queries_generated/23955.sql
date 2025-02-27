
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        ROW_NUMBER() OVER(PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
), 
SalesData As (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS total_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status, cd_education_status
    HAVING 
        COUNT(*) > 1
),
FinalReport AS (
    SELECT 
        s.ss_item_sk,
        COALESCE(s.total_sales, 0) AS total_web_sales,
        COALESCE(i.inv_quantity_on_hand, 0) AS inv_quantity,
        COALESCE(c.total_purchases, 0) AS total_customer_purchases,
        CASE 
            WHEN COALESCE(s.total_sales, 0) > 100 THEN 'High Performer'
            WHEN COALESCE(s.total_sales, 0) BETWEEN 50 AND 100 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END AS performance_category,
        COUNT(DISTINCT r.sr_ticket_number) AS return_count
    FROM 
        SalesData s
    FULL OUTER JOIN 
        inventory i ON s.ws_item_sk = i.inv_item_sk
    LEFT JOIN 
        CustomerData c ON c.c_customer_sk = (SELECT c_customer_sk FROM store_sales WHERE ss_item_sk = s.ws_item_sk LIMIT 1)
    LEFT JOIN 
        RankedReturns r ON r.sr_item_sk = s.ws_item_sk AND r.rn = 1
    GROUP BY 
        s.ss_item_sk, i.inv_quantity_on_hand, c.total_purchases
    HAVING 
        COALESCE(total_customer_purchases, 0) > 0 OR return_count > 0
)
SELECT 
    f.*, 
    f.performance_category || ' - Category' AS performance_label,
    CASE 
        WHEN f.return_count IS NULL THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_item_sk = f.ss_item_sk AND ws.ws_net_paid > 50) AS high_value_sales_count
FROM 
    FinalReport f
ORDER BY 
    f.total_web_sales DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
