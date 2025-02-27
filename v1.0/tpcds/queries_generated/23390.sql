
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_returned_date_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
), 
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesWithReturns AS (
    SELECT 
        is.ws_item_sk,
        ISNULL(ir.total_sold, 0) AS total_sales,
        ISNULL(rr.sr_return_quantity, 0) AS total_returns,
        ISNULL(ir.total_profit, 0) AS total_profit
    FROM 
        ItemSales ir
    FULL OUTER JOIN RankedReturns rr ON ir.ws_item_sk = rr.sr_item_sk AND rr.rnk = 1
), 
FinalReport AS (
    SELECT 
        swr.ws_item_sk,
        swr.total_sales,
        swr.total_returns,
        swr.total_profit,
        cd.c_first_name,
        cd.c_last_name,
        cd.purchase_estimate_category
    FROM 
        SalesWithReturns swr
    JOIN 
        CustomerDetails cd ON (swr.total_sales > 100 AND cd.cd_purchase_estimate >= 2000) 
        OR (swr.total_returns > 2 AND cd.cd_marital_status = 'M')
)

SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_returns,
    f.total_profit,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS customer_name,
    CASE 
        WHEN f.total_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalReport f
WHERE 
    f.total_sales IS NOT NULL
    AND (f.total_returns IS NULL OR f.total_returns < 5)
ORDER BY 
    f.total_profit DESC;
