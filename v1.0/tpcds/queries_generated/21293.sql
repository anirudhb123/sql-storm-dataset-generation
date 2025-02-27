
WITH RECURSIVE SalesGrowth AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank,
        d_year
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        ws_bill_customer_sk, d_year
),
TopCustomers AS (
    SELECT
        ws_bill_customer_sk,
        total_profit,
        profit_rank,
        d_year
    FROM
        SalesGrowth
    WHERE
        profit_rank <= 10
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnedSales AS (
    SELECT 
        wr.returned_date_sk,
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(wr_order_number) AS total_returned_orders
    FROM 
        web_returns wr
    GROUP BY 
        wr_returned_date_sk
),
ReturnAnalysis AS (
    SELECT 
        d_year,
        AVG(total_returned_amt) AS avg_return_amt,
        COUNT(DISTINCT wr_order_number) AS unique_returns
    FROM 
        ReturnedSales
    JOIN
        date_dim ON returned_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    CASE 
        WHEN cd.cd_gender IS NOT NULL THEN cd.cd_gender 
        ELSE 'Unknown' 
    END AS gender,
    COALESCE(top.total_profit, 0) AS total_profit,
    return.avg_return_amt,
    top.d_year
FROM 
    TopCustomers top
LEFT JOIN 
    CustomerDemographics cd ON top.ws_bill_customer_sk = cd.c_customer_sk
LEFT JOIN 
    ReturnAnalysis return ON top.d_year = return.d_year
WHERE 
    (cd_cd_gender IS NOT NULL AND cd_marital_status = 'M') 
    OR (cd_cd_gender IS NULL AND return.unique_returns > 0)
ORDER BY 
    total_profit DESC, gender;
