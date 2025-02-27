
WITH CustomerSegmentation AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_employed_dependents,
        SUM(cd_dep_college_count) AS total_college_dependents
    FROM 
        customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_cdemo_sk
),
ReturnData AS (
    SELECT 
        wr_returning_cdemo_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_cdemo_sk
),
CombinedData AS (
    SELECT 
        cs.cd_gender,
        cs.total_customers,
        cs.avg_purchase_estimate,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.net_profit, 0) AS net_profit,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.return_count, 0) AS return_count
    FROM 
        CustomerSegmentation cs
    LEFT JOIN SalesData sd ON cs.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = sd.ws_bill_cdemo_sk)
    LEFT JOIN ReturnData rd ON sd.ws_bill_cdemo_sk = rd.wr_returning_cdemo_sk
)

SELECT 
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    total_sales,
    net_profit,
    total_returned,
    return_count
FROM 
    CombinedData
ORDER BY 
    cd_gender;
