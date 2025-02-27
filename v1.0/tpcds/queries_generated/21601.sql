
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_date_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ship_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesSummary AS (
    SELECT 
        cs.ws_bill_customer_sk,
        SUM(cs.ws_sales_price) AS total_sales,
        AVG(cs.ws_net_profit) AS average_net_profit,
        COUNT(cs.ws_order_number) AS order_count
    FROM 
        web_sales cs
    GROUP BY 
        cs.ws_bill_customer_sk
), 
ReturnSummary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    ISNULL(cs.total_sales, 0) AS total_sales,
    ISNULL(rs.total_returned, 0) AS total_returned,
    (ISNULL(cs.total_sales, 0) - ISNULL(rs.total_returned, 0)) AS net_sales,
    (SELECT AVG(rs2.return_count) 
     FROM ReturnSummary rs2 
     WHERE rs2.total_returned IS NOT NULL) AS average_return_count,
    RANK() OVER (ORDER BY (ISNULL(cs.total_sales, 0) - ISNULL(rs.total_returned, 0)) DESC) AS sales_rank
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary cs ON cd.c_customer_id = cs.ws_bill_customer_sk
LEFT JOIN 
    ReturnSummary rs ON cd.c_customer_id = rs.sr_customer_sk
WHERE 
    cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    AND cd.cd_gender = 'F'
    OR cd.cd_marital_status = 'M'
ORDER BY 
    net_sales DESC, 
    cd.c_last_name ASC
FETCH FIRST 100 ROWS ONLY;
