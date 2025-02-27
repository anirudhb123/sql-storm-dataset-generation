
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sales_price > 100
),
ProfitAnalysis AS (
    SELECT 
        ra.web_site_sk,
        ra.order_number,
        ra.ws_sales_price,
        (ra.ws_sales_price - (SELECT AVG(rs.ws_sales_price) 
                              FROM RankedSales rs 
                              WHERE rs.web_site_sk = ra.web_site_sk)) AS price_variance,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS item_count,
        COUNT(DISTINCT r.r_reason_desc) AS reason_count
    FROM 
        RankedSales ra
    LEFT JOIN 
        web_returns wr ON ra.order_number = wr.wr_order_number
    LEFT JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY 
        ra.web_site_sk, ra.order_number, ra.ws_sales_price
),
FinalResults AS (
    SELECT 
        pa.web_site_sk,
        pa.order_number,
        pa.ws_sales_price,
        pa.price_variance,
        pa.item_count,
        pa.reason_count,
        CASE 
            WHEN pa.price_variance > 0 THEN 'Above Average'
            WHEN pa.price_variance < 0 THEN 'Below Average'
            ELSE 'Average'
        END AS price_category
    FROM 
        ProfitAnalysis pa
    WHERE 
        item_count > 0
)
SELECT 
    fw.web_site_id,
    fw.order_number,
    fw.ws_sales_price,
    fw.price_variance,
    fw.item_count,
    fw.reason_count,
    fw.price_category
FROM 
    FinalResults fw
JOIN 
    web_site ws ON fw.web_site_sk = ws.web_site_sk
WHERE 
    fw.item_count > (SELECT AVG(item_count) FROM FinalResults)
ORDER BY 
    fw.ws_sales_price DESC;
