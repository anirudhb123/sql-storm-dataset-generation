
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_sales_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
RankedCustomers AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        customer_count,
        RANK() OVER (PARTITION BY cd_gender ORDER BY customer_count DESC) AS gender_rank
    FROM 
        CustomerDemographics
),
FinalResults AS (
    SELECT 
        rc.cd_gender,
        rc.cd_marital_status,
        rc.customer_count,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales_profit, 0) AS total_sales_profit
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        CustomerReturns cr ON cr.sr_customer_sk = rc.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON sd.ws_bill_customer_sk = rc.cd_demo_sk
    WHERE 
        rc.gender_rank <= 5
)
SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    total_returns,
    total_return_amount,
    total_sales_profit,
    (CASE 
        WHEN total_sales_profit > 0 THEN ROUND((total_return_amount / total_sales_profit) * 100, 2) 
        ELSE NULL 
     END) AS return_percentage
FROM 
    FinalResults
ORDER BY 
    cd_gender, customer_count DESC;
