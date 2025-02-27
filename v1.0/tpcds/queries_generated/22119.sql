
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND ws.ws_net_profit > 0
),
AggregatedIncome AS (
    SELECT 
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
),
WarehouseSales AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_id
),
TotalSales AS (
    SELECT 
        'web' AS sales_channel, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2)
    UNION ALL
    SELECT 
        'store' AS sales_channel, 
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sales_price > (SELECT AVG(ss2.ss_sales_price) FROM store_sales ss2)
),
ReturnDetails AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    ca.ca_city,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(aps.total_net_profit, 0) AS total_profit,
    COALESCE(br.total_returns, 0) AS total_returns,
    RANK() OVER (ORDER BY COALESCE(s.total_sales, 0) DESC) AS city_rank
FROM 
    customer_address ca
LEFT JOIN 
    WarehouseSales s ON ca.ca_zip = s.w_warehouse_id -- Assuming same format for demonstrative purpose
LEFT JOIN 
    AggregatedIncome aps ON aps.hd_income_band_sk IN (SELECT DISTINCT hd.hd_income_band_sk FROM household_demographics hd WHERE hd.hd_dep_count IS NOT NULL AND hd.hd_dep_count > 2)
LEFT JOIN 
    ReturnDetails br ON br.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
WHERE 
    (ca.ca_state IS NULL OR ca.ca_state = 'CA') 
AND 
    EXISTS (SELECT 1 FROM RankedSales rs WHERE rs.ws_item_sk = ANY(ARRAY(SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_net_profit > 0))
    OR rs.sales_rank = 1)
ORDER BY 
    city_rank;
