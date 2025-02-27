
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
IncomeDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cr.hd_income_band_sk,
        COALESCE(SUM(cr.hd_dep_count), 0) AS total_dependencies,
        COUNT(DISTINCT cd.cd_demo_sk) OVER (PARTITION BY cr.hd_income_band_sk) AS unique_customers_in_band
    FROM 
        household_demographics cr
    LEFT JOIN 
        customer_demographics cd ON cr.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cr.hd_income_band_sk
),
WebSalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(*) AS number_of_transactions,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CatalogSalesSummary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS average_sales_price
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_ext_discount_amt IS NOT NULL
    GROUP BY 
        cs.cs_item_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    WHERE 
        ss.ss_net_paid_inc_tax > 100.00
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    s.ss_item_sk AS item_key,
    COALESCE(w.total_net_profit + c.total_net_profit + s.total_net_profit, 0) AS combined_profit,
    COALESCE(c.total_dependencies, 0) AS total_dependencies,
    COALESCE(w.total_quantity_sold, 0) AS web_quantity_sold,
    d.cd_gender AS demographic_gender,
    d.cd_marital_status AS demographic_marital_status
FROM 
    StoreSalesSummary s
FULL OUTER JOIN 
    WebSalesSummary w ON s.ss_item_sk = w.ws_item_sk
FULL OUTER JOIN 
    CatalogSalesSummary c ON s.ss_item_sk = c.cs_item_sk
LEFT JOIN 
    IncomeDemographics d ON s.ss_item_sk = d.hd_income_band_sk
WHERE 
    (COALESCE(w.total_net_profit, 0) <> 0 OR COALESCE(c.total_net_profit, 0) <> 0)
    AND COALESCE(d.unique_customers_in_band, 0) IS NOT NULL
ORDER BY 
    combined_profit DESC
LIMIT 1000;
