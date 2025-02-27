
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE (SELECT CONCAT('Income Band: ', ib_lower_bound, '-', ib_upper_bound) 
                  FROM income_band 
                  WHERE ib_income_band_sk = cd_income_band_sk)
        END AS income_band_range
    FROM 
        customer_demographics
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DateSummary AS (
    SELECT 
        d.d_date,
        COUNT(CASE WHEN b.total_return_quantity > 0 THEN 1 END) AS return_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        date_dim d
    LEFT JOIN CustomerReturns b ON d.d_date_sk = b.sr_returned_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
)
SELECT 
    d.d_date,
    cd.gender,
    cd.marital_status,
    ss.total_net_profit,
    ds.return_count,
    ds.sales_count,
    CASE 
        WHEN ds.return_count > 0 THEN 'Returns Exist'
        ELSE 'No Returns'
    END AS return_status
FROM 
    DateSummary ds
JOIN 
    SalesSummary ss ON ds.sales_count > 0 -- Ensuring we only consider dates with sales
JOIN 
    CustomerDemographics cd ON ss.ws_bill_customer_sk = cd.cd_demo_sk
WHERE 
    cd.purchase_estimate BETWEEN 100 AND 1000 
    AND cd.gender = 'F'
ORDER BY 
    ds.return_count DESC, ds.sales_count DESC
LIMIT 50;
