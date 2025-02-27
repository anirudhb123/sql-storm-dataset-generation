
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_net_paid > 100
),
IncomeBands AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'UNKNOWN'
            ELSE CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_band_range
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesDetails AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sale_count
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
),
FinalReport AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_net_paid,
        sd.sale_count,
        ib.income_band_range
    FROM 
        SalesDetails sd
    JOIN 
        IncomeBands ib ON sd.ws_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns)
    WHERE 
        sd.sale_count > 5
)
SELECT 
    fr.ws_item_sk,
    fr.total_net_paid,
    fr.sale_count,
    fr.income_band_range,
    CASE 
        WHEN fr.total_net_paid IS NULL THEN 'NO SALES'
        ELSE 'SALES RECORDED'
    END AS sales_status
FROM 
    FinalReport fr
LEFT JOIN 
    item i ON fr.ws_item_sk = i.i_item_sk
WHERE 
    (i.i_current_price > 20 OR i.i_current_price IS NULL)
    AND NOT EXISTS (
        SELECT 1 FROM store_sales ss 
        WHERE ss.ss_item_sk = fr.ws_item_sk 
        AND ss.ss_sales_price < (SELECT AVG(ss2.ss_sales_price) FROM store_sales ss2 WHERE ss2.ss_item_sk = fr.ws_item_sk)
    )
ORDER BY 
    fr.total_net_paid DESC NULLS LAST;
