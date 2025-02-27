
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS returned_items,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity,
        AVG(sr_return_tax) AS avg_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_order_number) AS order_count,
        SUM(ss_quantity) AS total_quantity_sold
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedReturns AS (
    SELECT 
        cr.sr_customer_sk, 
        cr.returned_items,
        cr.total_returned_amount,
        cr.total_returned_quantity,
        RANK() OVER (ORDER BY cr.total_returned_amount DESC) AS return_rank
    FROM 
        CustomerReturns cr
),
FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(r.returned_items, 0) AS returned_items,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        r.return_rank
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ss_customer_sk
    LEFT JOIN 
        RankedReturns r ON cd.c_customer_sk = r.sr_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_sales,
    fr.order_count,
    fr.total_quantity_sold,
    fr.returned_items,
    fr.total_returned_amount,
    fr.total_returned_quantity,
    CASE 
        WHEN fr.return_rank IS NULL THEN 'No Returns'
        WHEN fr.return_rank <= 10 THEN 'Top Returner'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    FinalReport fr
WHERE 
    (fr.total_sales - fr.total_returned_amount) > 1000 OR fr.returned_quantity > 10
ORDER BY 
    fr.total_sales DESC, fr.total_returned_amount ASC
LIMIT 50;
