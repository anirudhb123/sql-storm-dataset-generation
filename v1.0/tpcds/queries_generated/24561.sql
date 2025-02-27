
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_quantity DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
    )
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        AVG(wr_return_amt) AS avg_return_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_demographics 
        ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
SalesDetails AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM web_sales ws
    JOIN customer c 
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    cd.gender,
    cd.marital_status,
    COALESCE(COUNT(DISTINCT cs.c_customer_id), 0) AS total_customers,
    COALESCE(SUM(ws.total_sales), 0) AS total_sales,
    COALESCE(SUM(cr.total_returned_quantity), 0) AS total_returns,
    COALESCE(AVG(cr.avg_return_amt), 0) AS avg_return_amount,
    COALESCE(MAX(ws.max_sales_price), 0) AS highest_sale_price
FROM CustomerDemographics cd
LEFT JOIN SalesDetails ws 
    ON cd.customer_count > 10
LEFT JOIN CustomerReturns cr 
    ON cd.cd_demo_sk = cr.wr_returning_customer_sk
GROUP BY cd.gender, cd.marital_status
HAVING SUM(ws.total_sales) > (
    SELECT AVG(total_sales)
    FROM (
        SELECT 
            SUM(ws_sales_price * ws_quantity) as total_sales
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) AS sales_summary
) OR (cd.gender IS NULL AND cd.marital_status IS NOT NULL)
ORDER BY total_customers DESC, total_sales DESC;
