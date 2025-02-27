
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
HighPerformingSites AS (
    SELECT 
        wr.web_site_sk,
        r.reason_desc,
        SUM(wr.wr_return_amt) AS total_returns
    FROM 
        web_returns wr
    JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
    WHERE 
        wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr.web_site_sk, r.reason_desc
),
SalesSummary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        COALESCE(SUM(hd.hd_dep_count), 0) AS household_dependents,
        COALESCE(AVG(hd.hd_vehicle_count), 0) AS average_vehicle_count
    FROM 
        store_sales ss
    LEFT JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN 
        household_demographics hd ON ss.ss_customer_sk = hd.hd_demo_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    RHS.web_site_sk,
    RHS.total_sales,
    HPS.total_returns,
    SS.total_net_profit,
    SS.transaction_count,
    SS.household_dependents,
    SS.average_vehicle_count
FROM 
    RankedSales RHS
LEFT JOIN 
    HighPerformingSites HPS ON RHS.web_site_sk = HPS.web_site_sk
JOIN 
    SalesSummary SS ON SS.s_store_id = (SELECT s_store_id FROM store WHERE s_store_sk = (SELECT ss.ss_store_sk FROM store_sales ss WHERE ss.ws_web_site_sk = RHS.web_site_sk LIMIT 1))
WHERE 
    RHS.sales_rank = 1 AND 
    (HPS.total_returns IS NULL OR HPS.total_returns < 100)
ORDER BY 
    RHS.total_sales DESC;
