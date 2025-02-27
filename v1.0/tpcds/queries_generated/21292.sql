
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(Ranked.total_quantity, 0) AS quantity_sold,
        COALESCE(Ranked.total_sales, 0) AS total_sales_value,
        CASE 
            WHEN COUNT(store.ss_item_sk) = 0 THEN 'No Sales'
            ELSE 'Sales Exist'
        END AS sales_status
    FROM 
        item
    LEFT JOIN 
        RankedSales Ranked ON item.i_item_sk = Ranked.ws_item_sk
    LEFT JOIN 
        store_sales store ON item.i_item_sk = store.ss_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc, Ranked.total_quantity, Ranked.total_sales
),
StoreSalesStats AS (
    SELECT 
        ss_store_sk,
        AVG(ss_net_profit) AS avg_net_profit,
        MAX(ss_net_profit) AS max_net_profit,
        MIN(ss_net_profit) AS min_net_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(CASE 
            WHEN cd_marital_status = 'M' THEN 1 
            ELSE 0 
        END), 0) AS married_count,
        COALESCE(SUM(CASE 
            WHEN cd_credit_rating IS NULL THEN 1 
            ELSE 0 
        END), 0) AS no_credit_rating_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.quantity_sold,
    ss.total_sales_value,
    ss.sales_status,
    COALESCE(sss.avg_net_profit, 0) AS avg_store_profit,
    cs.married_count,
    cs.no_credit_rating_count,
    cs.avg_purchase_estimate
FROM 
    SalesSummary ss
LEFT JOIN 
    StoreSalesStats sss ON ss.quantity_sold > 100
LEFT JOIN 
    CustomerStats cs ON ss.total_sales_value > sss.avg_net_profit
WHERE 
    ss.total_sales_value > 0
ORDER BY 
    ss.total_sales_value DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
