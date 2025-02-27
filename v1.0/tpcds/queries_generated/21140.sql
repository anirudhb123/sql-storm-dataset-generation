
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.average_profit,
        sd.sales_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.sr_item_sk
)
SELECT 
    rc.c_customer_sk,
    rc.c_customer_id,
    COALESCE(fs.total_sales, 0) AS total_sales,
    COALESCE(fs.total_returns, 0) AS total_returns,
    fs.average_profit,
    fs.sales_rank
FROM 
    RankedCustomers rc
LEFT JOIN 
    FinalSales fs ON fs.ws_item_sk = (SELECT MAX(i_item_sk) 
                                       FROM item 
                                       WHERE i_item_id = 
                                       (CASE 
                                            WHEN rc.rnk = 1 THEN 'BEST_SELLER'
                                            ELSE 'UNKNOWN_ITEM'
                                        END))
WHERE 
    rc.rnk <= 10 AND 
    (rc.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics) 
     OR rc.cd_gender IS NULL)
ORDER BY 
    rc.cd_gender DESC, 
    rc.cd_marital_status, 
    total_sales DESC;
