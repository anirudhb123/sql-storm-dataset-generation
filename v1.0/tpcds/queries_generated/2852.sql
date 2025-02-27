
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.return_quantity) AS total_returned_quantity,
        SUM(wr.return_amt) AS total_return_amt,
        COUNT(*) AS total_return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        cd.education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(COALESCE(cd.purchase_estimate, 0)) AS total_estimated_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender, cd.marital_status, cd.education_status
)

SELECT 
    c.customer_count,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    COALESCE(cr.total_returned_quantity, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    SUM(rs.ws_quantity * rs.ws_sales_price) AS total_sales,
    AVG(rs.ws_net_profit) AS average_net_profit
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.customer_count > 100
LEFT JOIN 
    RankedSales rs ON cd.customer_count > 0 AND rs.rank_profit <= 10
GROUP BY 
    cd.gender, 
    cd.marital_status, 
    cd.education_status, 
    cr.total_returned_quantity, 
    cr.total_return_amt
HAVING 
    SUM(rs.ws_quantity) > 1000 OR 
    COUNT(DISTINCT rs.ws_order_number) > 5
ORDER BY 
    total_sales DESC, 
    average_net_profit DESC;
