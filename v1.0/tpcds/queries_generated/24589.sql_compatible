
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM
        web_sales
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COUNT(cs_order_number) AS order_count,
        COUNT(DISTINCT r.r_reason_desc) AS unique_reasons
    FROM
        catalog_sales cs
    LEFT JOIN CustomerReturns cr ON cs_bill_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN reason r ON r.r_reason_sk = (SELECT cr_reason_sk FROM catalog_returns WHERE cr_order_number = cs_order_number LIMIT 1)
    GROUP BY cs_bill_customer_sk
),
TopCustomers AS (
    SELECT
        customer_sk,
        total_sales,
        total_returns,
        order_count,
        unique_reasons,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesAndReturns
)
SELECT
    tc.customer_sk,
    tc.total_sales,
    tc.total_returns,
    tc.order_count,
    tc.unique_reasons,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(NULLIF(RANK() OVER (ORDER BY tc.unique_reasons DESC), 1), (SELECT COUNT(*) FROM TopCustomers)) AS uniqueness_rank
FROM
    TopCustomers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC,
    tc.total_returns ASC;
