
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        demographics.cd_gender,
        sales.total_sales
    FROM 
        customer
    JOIN 
        customer_demographics demographics ON customer.c_current_cdemo_sk = demographics.cd_demo_sk
    JOIN 
        SalesCTE sales ON sales.ws_bill_customer_sk = customer.c_customer_sk
    WHERE 
        sales.total_sales > (SELECT AVG(total_sales) FROM SalesCTE)
), 
RecentReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returned,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(rr.total_returned, 0) AS total_returned,
    hvc.total_sales,
    (hvc.total_sales - COALESCE(rr.total_returned, 0)) AS net_sales,
    CASE 
        WHEN rr.total_returned IS NULL THEN 'No Returns'
        WHEN rr.total_returned > hvc.total_sales THEN 'High Return Customer'
        ELSE 'Normal Customer' 
    END AS customer_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentReturns rr ON hvc.c_customer_id = rr.wr_returning_customer_sk
ORDER BY 
    hvc.total_sales DESC, 
    net_sales ASC
LIMIT 100;
