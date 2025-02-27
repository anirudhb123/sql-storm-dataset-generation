
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 0 AND 1000
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
CustomerWithReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
FinalCustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cwr.return_count, 0) AS total_store_returns,
        COALESCE(cwr.web_return_count, 0) AS total_web_returns
    FROM 
        customer c
    LEFT JOIN 
        CustomerWithReturns cwr ON c.c_customer_id = cwr.c_customer_id
),
CustomerIncome AS (
    SELECT 
        h.hd_demo_sk,
        COALESCE(i.ib_lower_bound, 0) AS income_band_lower,
        COALESCE(i.ib_upper_bound, 0) AS income_band_upper,
        SUM(r.return_count) AS total_returned
    FROM 
        household_demographics h
    LEFT JOIN 
        income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    LEFT JOIN 
        CustomerWithReturns r ON h.hd_demo_sk = r.c_customer_id
    GROUP BY 
        h.hd_demo_sk, i.ib_lower_bound, i.ib_upper_bound
)
SELECT 
    fcs.c_customer_id,
    fcs.total_store_returns,
    fcs.total_web_returns,
    ci.income_band_lower,
    ci.income_band_upper,
    nh.niche_count
FROM 
    FinalCustomerStats fcs
LEFT JOIN 
    CustomerIncome ci ON fcs.c_customer_id = ci.hd_demo_sk
JOIN (
    SELECT 
        ws_item_sk,
        COUNT(*) AS niche_count
    FROM 
        RankedSales
    WHERE 
        profit_rank > 5 
    GROUP BY 
        ws_item_sk
) nh ON ci.income_band_lower < nh.niche_count AND ci.income_band_upper > nh.niche_count
WHERE 
    fcs.total_store_returns IS NOT NULL AND 
    (fcs.total_web_returns IS NULL OR fcs.total_web_returns > 0)
ORDER BY 
    fcs.total_store_returns DESC, 
    fcs.total_web_returns ASC 
FETCH FIRST 100 ROWS ONLY;
