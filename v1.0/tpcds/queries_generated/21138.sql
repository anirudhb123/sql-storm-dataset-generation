
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
CustomerAggregates AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.item_sk) AS unique_return_items,
        SUM(sr.return_amt) AS total_return_amt,
        AVG(sr.return_quantity) AS avg_return_qty
    FROM customer c
    LEFT JOIN RankedReturns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
    HAVING COUNT(DISTINCT sr.item_sk) > 1 AND SUM(sr.return_amt) IS NOT NULL
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_stock,
        AVG(i.inv_quantity_on_hand) AS avg_stock_per_item
    FROM warehouse w
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(ca.returning_customer_count, 0) AS returning_customers,
    COALESCE(ws.total_stock, 0) AS total_warehouse_stock,
    ROUND(SUM(c.total_return_amt), 2) AS total_returns_amount,
    ROUND(AVG(c.avg_return_qty), 2) AS avg_return_quantity_per_customer
FROM customer_address ca
LEFT OUTER JOIN (
    SELECT 
        ca_address_sk,
        COUNT(*) AS returning_customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' 
    GROUP BY ca_address_sk
) ca ON ca.ca_address_sk = ca.ca_address_sk
LEFT JOIN WarehouseStats ws ON 1=1 -- Cartesian Join for demonstration purposes
JOIN CustomerAggregates c ON c.c_customer_sk = ca.ca_address_sk -- Intentionally using ca_address_sk for correlation
GROUP BY 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,    
    ws.total_stock
ORDER BY 
    total_returns_amount DESC,
    returning_customers DESC
LIMIT 100
UNION ALL
SELECT 
    NULL AS ca_city,
    NULL AS ca_state,
    NULL AS ca_country,
    COUNT(DISTINCT c.c_customer_id) AS returning_customers,
    NULL AS total_warehouse_stock,
    ROUND(SUM(COALESCE(case when c.c_first_shipto_date_sk is not NULL then sr_return_amt END, 0)), 2) AS total_returns_amount,
    ROUND(AVG(COALESCE(case when sr_return_quantity IS NOT NULL then sr_return_quantity END, NULL)), 2) AS avg_return_quantity_per_customer
FROM customer c
JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE sr_return_quantity IS NOT NULL
AND sr_return_amt < (SELECT AVG(ws.ws_net_paid) FROM web_sales ws)
ORDER BY 1;
