
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_store_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS return_rank
    FROM 
        store_returns
),
CustomerClassifications AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' AND hd.hd_income_band_sk IS NOT NULL THEN 'Male - Income Band'
            WHEN cd.cd_gender = 'F' AND hd.hd_income_band_sk IS NOT NULL THEN 'Female - Income Band'
            ELSE 'Other'
        END AS customer_classification
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales_quantity, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    WHERE 
        ws_net_profit IS NOT NULL
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
) 
SELECT 
    w.ws_sold_date_sk, 
    i.i_item_desc, 
    cs.customer_classification,
    COALESCE(r.return_rank, 0) AS return_rank,
    SUM(ss.total_sales_quantity) AS total_sales,
    SUM(ss.total_net_profit) AS total_net_profit
FROM 
    SalesSummary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
LEFT JOIN 
    RankedReturns r ON i.i_item_sk = r.sr_item_sk AND r.return_rank <= 10
LEFT JOIN 
    CustomerClassifications cs ON cs.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.total_sales > 0
GROUP BY 
    w.ws_sold_date_sk, 
    i.i_item_desc, 
    cs.customer_classification, 
    r.return_rank
ORDER BY 
    total_net_profit DESC, 
    total_sales DESC;
