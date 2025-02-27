
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    c.c_customer_id,
    cc.total_returns,
    cc.total_return_amount,
    COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(s.total_profit, 0) AS total_profit,
    RANK() OVER (ORDER BY COALESCE(cc.total_return_amount, 0) DESC) AS rank_return_value,
    r.total_quantity AS rank_based_on_sales
FROM 
    CustomerReturns cc
LEFT JOIN 
    HighValueCustomers hv ON cc.wr_returning_customer_sk = hv.c_customer_id
LEFT JOIN 
    SalesSummary s ON hv.c_customer_id = s.i_item_id
LEFT JOIN 
    RankedSales r ON s.i_item_id = r.ws_item_sk
WHERE 
    cc.total_returns > 5 AND
    (hv.cd_marital_status = 'M' OR hv.cd_gender = 'F')
ORDER BY 
    total_return_amount DESC, 
    total_quantity_sold DESC;
