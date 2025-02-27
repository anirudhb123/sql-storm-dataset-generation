
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c_customer_sk END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c_customer_sk END) AS male_customers,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk
),
TopSellingItems AS (
    SELECT 
        i_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    INNER JOIN 
        item i ON ws_item_sk = i.i_item_sk
    WHERE 
        ws_net_profit IS NOT NULL
    GROUP BY 
        i_item_sk
    HAVING 
        SUM(ws_net_profit) > 5000
),
SelectedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_item_sk
),
FinalStats AS (
    SELECT 
        tsi.i_item_sk,
        tsi.total_profit,
        tsi.total_orders,
        sr.total_returns,
        COUNT(DISTINCT cs.c_customer_sk) AS unique_customers
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        SelectedReturns sr ON tsi.i_item_sk = sr.sr_item_sk
    LEFT JOIN 
        CustomerStats cs ON cs.c_customer_sk IN (
            SELECT DISTINCT 
                ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = tsi.i_item_sk
        )
    GROUP BY 
        tsi.i_item_sk, tsi.total_profit, tsi.total_orders, sr.total_returns
)
SELECT 
    f.i_item_sk,
    f.total_profit,
    f.total_orders,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.unique_customers, 0) AS unique_customers,
    CASE 
        WHEN f.total_profit > 10000 THEN 'High Profit'
        WHEN f.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalStats f
ORDER BY 
    f.total_profit DESC;
