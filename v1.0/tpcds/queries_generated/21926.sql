
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd_purchase_estimate < 1000 THEN 'LOW'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_estimate_category
    FROM 
        customer_demographics 
),
MaxReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk 
    HAVING 
        COUNT(*) > 0
),
FinalReport AS (
    SELECT 
        cs.i_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_net_profit,
        COALESCE(MAX(mr.total_returns), 0) AS max_returns,
        COALESCE(cd.purchase_estimate_category, 'UNDETERMINED') AS purchase_category,
        SUM(CASE 
            WHEN ws.total_quantity > 100 THEN ws.total_sales * 0.1 
            ELSE ws.total_sales * 0.05 
        END) AS adjusted_sales
    FROM 
        RankedSales AS ws
    LEFT JOIN 
        catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN 
        MaxReturns AS mr ON ws.ws_item_sk = mr.sr_item_sk
    LEFT JOIN 
        CustomerDemographics AS cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cs.i_item_sk, cd.purchase_estimate_category
    HAVING 
        SUM(adjusted_sales) IS NOT NULL
        AND COUNT(DISTINCT cs.cs_order_number) > 0
)
SELECT 
    f.i_item_sk,
    f.total_orders,
    f.total_net_profit,
    f.max_returns,
    f.purchase_category,
    CASE 
        WHEN f.adjusted_sales > 5000 THEN 'HIGH SALES'
        ELSE 'LOW SALES'
    END AS sales_performance
FROM 
    FinalReport AS f
ORDER BY 
    f.total_net_profit DESC, 
    f.total_orders ASC
LIMIT 10;
