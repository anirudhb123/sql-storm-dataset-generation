
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COALESCE(SUM(CASE WHEN ws.ws_sales_price > 50 THEN 1 ELSE 0 END), 0) AS high_value_purchases,
        COALESCE(AVG(ws.ws_sales_price), 0) AS avg_purchase_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
ReturnReasons AS (
    SELECT 
        sr_item_sk,
        r.r_reason_desc,
        COUNT(*) AS return_count
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        sr_item_sk, r.r_reason_desc
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END) AS total_catalog_sales,
    SUM(CASE WHEN rs.ws_sales_price IS NOT NULL AND rs.price_rank = 1 THEN rs.ws_sales_price ELSE 0 END) AS top_web_sales,
    COUNT(rr.r_reason_desc) FILTER (WHERE rr.return_count > 0) AS num_returned_items,
    MAX(cs.avg_purchase_amount) AS max_avg_purchase_amount
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = cs.cs_item_sk
LEFT JOIN 
    ReturnReasons rr ON rr.sr_item_sk = cs.cs_item_sk
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_catalog_sales DESC;
