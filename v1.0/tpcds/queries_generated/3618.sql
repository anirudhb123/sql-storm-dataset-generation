
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 0
),
CustomerAggregates AS (
    SELECT 
        c.c_customer_id,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_current_addr_sk) AS distinct_addresses
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
SalesWithReturnInfo AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amt,
        SUM(ws.ws_sales_price) - COALESCE(SUM(sr_return_amt), 0) AS net_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    cagg.c_customer_id,
    cagg.avg_purchase_estimate,
    cagg.distinct_addresses,
    COALESCE(sswi.total_sales, 0) AS total_sales,
    COALESCE(sswi.total_return_amt, 0) AS total_return_amt,
    sswi.net_sales,
    rks.web_site_id,
    rks.ws_order_number,
    rks.ws_sales_price,
    rks.ws_quantity
FROM 
    CustomerAggregates cagg
LEFT JOIN 
    SalesWithReturnInfo sswi ON cagg.c_customer_id = CAST(sswi.total_sales AS CHAR(16))
JOIN 
    RankedSales rks ON rks.ws_order_number = sswi.ws_order_number 
WHERE 
    cagg.avg_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    AND rks.price_rank <= 10
ORDER BY 
    cagg.avg_purchase_estimate DESC, rks.ws_sales_price DESC;
