
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rnk
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        dd.d_year,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items,
        SUM(rs.total_sales) AS total_spent,
        SUM(CASE WHEN rs.total_quantity IS NULL THEN 0 ELSE rs.total_quantity END) AS total_quantity
    FROM customer c
    LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    JOIN date_dim dd ON dd.d_date_sk = (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_year = 2022 AND d_current_year = 'Y'
    )
    GROUP BY c.c_customer_sk, dd.d_year
    HAVING SUM(rs.total_sales) > 1000
),
StoreSalesStats AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_net_profit) AS avg_net_profit,
        SUM(ss_ext_sales_price) AS total_sales_amt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ss_store_sk
),
CustomerFeedback AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status,
        COUNT(wp wp_web_page_sk) AS page_visits,
        SUM(COALESCE(wr_return_amt, 0)) AS total_returns
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, cd_marital_status
)
SELECT
    HVC.c_customer_sk,
    HVC.total_spent,
    HVC.unique_items,
    COALESCE(SSt.total_sales_amt, 0) AS total_store_sales,
    CFB.marital_status,
    CFB.total_returns,
    CASE 
        WHEN HVC.total_spent > 5000 THEN 'VIP'
        WHEN HVC.total_spent BETWEEN 2000 AND 5000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_tier
FROM HighValueCustomers HVC
LEFT JOIN StoreSalesStats SSt ON HVC.c_customer_sk = SSt.ss_store_sk
LEFT JOIN CustomerFeedback CFB ON HVC.c_customer_sk = CFB.c_customer_sk
WHERE HVC.total_quantity >= (
    SELECT AVG(total_quantity) FROM RankedSales
)
ORDER BY HVC.total_spent DESC, HVC.unique_items ASC;
