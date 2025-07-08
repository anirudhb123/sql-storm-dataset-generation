
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_profit,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_loss
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
IncomeDistribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cs.total_profit) AS avg_profit_per_customer
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        CustomerStats cs ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        h.hd_income_band_sk
),
SalesReport AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(ss.ss_quantity) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)

SELECT 
    COALESCE(id.hd_income_band_sk, 0) AS income_band,
    id.customer_count,
    id.avg_profit_per_customer,
    sr.i_item_id,
    sr.total_web_sales,
    sr.total_catalog_sales,
    sr.total_store_sales,
    sr.total_web_profit,
    sr.total_catalog_profit,
    sr.total_store_profit
FROM 
    IncomeDistribution id
FULL OUTER JOIN 
    SalesReport sr ON id.hd_income_band_sk = sr.i_item_sk
WHERE 
    id.customer_count > 10
ORDER BY 
    id.avg_profit_per_customer DESC, 
    sr.total_web_sales DESC;
