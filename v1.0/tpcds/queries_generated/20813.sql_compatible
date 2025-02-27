
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ReturnAnalysis AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS unique_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
CombinedSales AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity,
        sa.avg_sales_price,
        sa.total_net_profit,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ra.unique_returns, 0) AS unique_returns,
        sa.sales_rank,
        CASE 
            WHEN ra.unique_returns IS NULL THEN 'No Returns'
            WHEN ra.unique_returns > 10 THEN 'Frequent Returns'
            ELSE 'Normal Returns' 
        END AS return_category
    FROM 
        SalesAnalysis sa
    LEFT JOIN 
        ReturnAnalysis ra ON sa.ws_item_sk = ra.cr_item_sk
),
CustomerRank AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        cs.ws_item_sk,
        cs.total_quantity,
        cs.avg_sales_price,
        cs.total_net_profit,
        cs.total_return_quantity,
        cs.unique_returns,
        cs.sales_rank,
        cs.return_category
    FROM 
        CustomerInfo ci
    JOIN 
        CombinedSales cs ON ci.rn = 1
    WHERE 
        ci.cd_purchase_estimate IS NOT NULL
)
SELECT 
    cr.c_customer_id,
    cr.cd_gender,
    cr.return_category,
    SUM(cr.total_net_profit) AS total_net_profit_over_customers,
    COUNT(DISTINCT cr.ws_item_sk) AS total_unique_items,
    CASE 
        WHEN SUM(cr.total_net_profit) > 5000 THEN 'High Spender'
        WHEN SUM(cr.total_net_profit) BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    CustomerRank cr
GROUP BY 
    cr.c_customer_id,
    cr.cd_gender,
    cr.return_category
ORDER BY 
    total_net_profit_over_customers DESC, 
    cr.c_customer_id
LIMIT 100;
