
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(sr.return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr.return_quantity), 0) AS total_web_returns,
        COUNT(DISTINCT sr.ticket_number) AS store_return_count,
        COUNT(DISTINCT wr.order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        order_count > 100
),
HighIncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk, 
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_upper_bound > 100000
        AND hd.hd_dep_count IS NOT NULL
    GROUP BY 
        hd.hd_demo_sk, ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_online_profit,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk
),
FinalReport AS (
    SELECT 
        cr.c_customer_sk,
        ip.ws_item_sk,
        ip.total_sales,
        cr.total_store_returns,
        cr.total_web_returns,
        cr.store_return_count,
        cr.web_return_count,
        sb.total_online_profit,
        sb.total_store_profit
    FROM 
        CustomerReturns cr
    JOIN 
        PopularItems ip ON cr.c_customer_sk = (SELECT TOP 1 c.c_customer_sk FROM customer c WHERE c.c_customer_sk = cr.c_customer_sk)
    LEFT JOIN 
        SalesSummary sb ON sb.w_warehouse_sk = (SELECT DISTINCT ss.ss_store_sk FROM store_sales ss WHERE ss.ss_customer_sk = cr.c_customer_sk)
)
SELECT 
    f.c_customer_sk,
    f.ws_item_sk,
    f.total_sales,
    f.total_store_returns,
    f.total_web_returns,
    f.store_return_count,
    f.web_return_count,
    f.total_online_profit,
    f.total_store_profit
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC, 
    f.store_return_count DESC
LIMIT 100;
