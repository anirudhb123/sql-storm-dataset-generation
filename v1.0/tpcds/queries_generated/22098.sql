
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
ImpactFactors AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca 
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_address_sk
),
FrequentReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_return_quantity
),
CrossDepartmentalAnalysis AS (
    SELECT 
        iw.i_item_id, 
        iw.i_product_name, 
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_returns,
        COALESCE(SUM(wr.w_net_loss), 0) AS total_web_returns,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns
    FROM 
        item iw
    LEFT JOIN 
        web_sales ws ON iw.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON iw.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON iw.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        catalog_returns cr ON iw.i_item_sk = cr.cr_item_sk
    LEFT JOIN 
        web_returns wr ON iw.i_item_sk = wr.wr_item_sk
    LEFT JOIN 
        store_returns sr ON iw.i_item_sk = sr.sr_item_sk
    GROUP BY 
        iw.i_item_id, iw.i_product_name
)
SELECT 
    cd.ca_address_sk,
    COALESCE(r.total_web_profit, 0) AS total_web_profit,
    COALESCE(r.total_catalog_profit, 0) AS total_catalog_profit,
    COALESCE(r.total_store_profit, 0) AS total_store_profit,
    COALESCE(f.return_count, 0) AS frequent_returns_count,
    (SELECT COUNT(*) FROM FrequentReturns fr WHERE fr.sr_return_quantity > 10) AS high_volume_returns,
    (SELECT AVG(cd.avg_purchase_estimate) FROM ImpactFactors cd WHERE customer_count > 10) AS avg_high_customer_segment
FROM 
    ImpactFactors cd
FULL OUTER JOIN 
    CrossDepartmentalAnalysis r ON cd.ca_address_sk = r.ca_address_sk
LEFT JOIN 
    FrequentReturns f ON r.i_item_sk = f.sr_item_sk
WHERE 
    (r.total_web_profit > 1000 OR r.total_catalog_profit > 1000 OR r.total_store_profit > 1000)
    AND (f.return_count IS NULL OR f.return_count <= 5)
ORDER BY 
    cd.customer_count DESC, 
    r.total_web_profit DESC
LIMIT 50;
