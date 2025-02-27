
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_net_loss) AS total_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(cr.total_net_loss, 0) AS total_net_loss,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_orders, 0) AS total_orders,
    CASE 
        WHEN ss.total_sales > 0 THEN ss.total_profit / ss.total_sales 
        ELSE NULL 
    END AS profit_margin
FROM 
    CustomerDemographics AS cd
LEFT JOIN 
    CustomerReturns AS cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesSummary AS ss ON cd.c_customer_sk = ss.customer_sk
WHERE 
    cd.cd_gender IS NOT NULL AND 
    cd.cd_marital_status = 'M' AND 
    (cd.cd_purchase_estimate > 1000 OR cr.total_returns > 5)
ORDER BY 
    profit_margin DESC
FETCH FIRST 50 ROWS ONLY;
