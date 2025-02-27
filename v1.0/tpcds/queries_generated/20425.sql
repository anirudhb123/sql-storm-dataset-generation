
WITH RankedSales AS (
    SELECT 
        cs_ship_date_sk,
        cs_item_sk,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS rn
    FROM catalog_sales
    WHERE cs_item_sk IS NOT NULL AND cs_net_profit > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        COUNT(DISTINCT cd_demo_sk) AS total_demographics,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id
),
ReturnDetails AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_fee) AS total_fees
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_returned_date_sk
)
SELECT 
    ds.d_date AS sales_date,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    COALESCE(SUM(rs.cs_net_profit), 0) AS total_catalog_sales_profit,
    COUNT(DISTINCT cs.c_customer_id) AS unique_customers,
    SUM(cd.female_count) AS total_females,
    MAX(cd.max_purchase_estimate) AS highest_purchase_estimate,
    CASE 
        WHEN SUM(rd.total_returns) IS NULL THEN 'No Returns'
        WHEN SUM(rd.total_returns) > 0 THEN 'Some Returns'
        ELSE 'Unexpected'
    END AS return_status,
    GROUP_CONCAT(DISTINCT s.s_store_name ORDER BY s.s_store_name ASC) AS store_names,
    (SELECT 
        COUNT(*) 
     FROM ship_mode 
     WHERE sm_carrier LIKE '%Air%' OR sm_type IS NULL) AS air_related_ship_modes
FROM date_dim AS ds
LEFT JOIN web_sales AS ws ON ws.ws_sold_date_sk = ds.d_date_sk
LEFT JOIN RankedSales AS rs ON rs.cs_ship_date_sk = ds.d_date_sk
LEFT JOIN CustomerStats AS cs ON cs.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN ReturnDetails AS rd ON rd.sr_returned_date_sk = ds.d_date_sk
LEFT JOIN store AS s ON s.s_store_sk = ws.ws_warehouse_sk
WHERE ds.d_date >= '2023-01-01' AND ds.d_date < '2024-01-01'
GROUP BY ds.d_date
HAVING total_sales_profit IS NOT NULL AND unique_customers > 10
ORDER BY sales_date DESC
```
