
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_quantity > 0
),
FilteredReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity IS NOT NULL
        AND wr.wr_return_amt IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
),
CombinedSalesReturns AS (
    SELECT 
        rs.ws_item_sk,
        COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) AS total_sales,
        COALESCE(fr.total_returns, 0) AS total_returns,
        COALESCE(fr.avg_return_amt, 0) AS avg_return_amt
    FROM 
        RankedSales rs
    LEFT JOIN 
        FilteredReturns fr ON rs.ws_item_sk = fr.wr_item_sk
    GROUP BY 
        rs.ws_item_sk
),
IncomeAdjustment AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(DISTINCT hh.hd_demo_sk) AS customer_count,
        SUM(cs.cs_net_profit) * CASE 
            WHEN hh.hd_income_band_sk IS NULL THEN 1 
            ELSE (1 + (SELECT ib.ib_upper_bound 
                        FROM income_band ib 
                        WHERE ib.ib_income_band_sk = hh.hd_income_band_sk) / 100.0)
        END AS adjusted_profit
    FROM 
        catalog_sales cs
    JOIN 
        household_demographics hh ON cs.cs_bill_cdemo_sk = hh.hd_demo_sk
    WHERE 
        cs.cs_net_profit IS NOT NULL
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    csar.ws_item_sk,
    csar.total_sales,
    csar.total_returns,
    csar.avg_return_amt,
    ia.customer_count,
    ia.adjusted_profit
FROM 
    CombinedSalesReturns csar
JOIN 
    IncomeAdjustment ia ON csar.ws_item_sk = ia.cs_item_sk
ORDER BY 
    csar.total_sales DESC, 
    ia.adjusted_profit ASC
LIMIT 50;
