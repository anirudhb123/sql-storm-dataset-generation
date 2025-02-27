
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_id,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        CASE 
            WHEN COUNT(DISTINCT sr_ticket_number) > 10 THEN 'Frequent Returner'
            WHEN SUM(sr_return_amt_inc_tax) > 1000 THEN 'High Value Returner'
            ELSE 'Occasional Returner'
        END AS return_category
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighReturns AS (
    SELECT 
        cr.customer_id,
        cr.return_count,
        cr.total_return_amount,
        cr.return_category,
        cd_gender,
        cd_marital_status
    FROM CustomerReturns cr
    JOIN customer_demographics cd ON cr.customer_id = cd.cd_demo_sk
    WHERE cr.return_count > (SELECT AVG(return_count) FROM CustomerReturns)
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        sd.customer_id,
        COALESCE(hd.return_count, 0) AS return_count,
        sd.total_sales,
        sd.order_count 
    FROM SalesData sd
    LEFT JOIN HighReturns hd ON sd.customer_id = hd.customer_id
),
RankingData AS (
    SELECT 
        cs.*,
        RANK() OVER (ORDER BY cs.total_sales DESC, cs.return_count ASC) AS sales_rank
    FROM CustomerSales cs
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cs.return_count,
    cs.total_sales,
    cs.order_count,
    rd.sales_rank
FROM RankingData rd
JOIN customer cd ON rd.customer_id = cd.c_customer_sk
WHERE 
    rd.total_sales > 500
    OR (rd.return_count > 2 AND rd.sales_rank < 50)
ORDER BY 
    rd.sales_rank, 
    cd.c_last_name;
