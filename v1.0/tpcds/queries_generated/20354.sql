
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS customer_sales_row,
        COALESCE(CAST(SUBSTRING_INDEX(wp.wp_url, '/', -1) AS DECIMAL), 0) AS page_references
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        ws.ws_item_sk, ws.ws_customer_sk
),
CustomerSegmentation AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' THEN 'Married Male'
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Female'
            ELSE 'Other'
        END AS customer_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemReturnStats AS (
    SELECT 
        ir.ir_item_sk,
        COALESCE(SUM(ir.ir_return_quantity), 0) AS total_returned_quantity,
        AVG(ir.ir_return_amt) AS avg_return_amount
    FROM 
        (SELECT cr.cr_item_sk AS ir_item_sk, cr.cr_return_quantity AS ir_return_quantity, cr.cr_return_amount AS ir_return_amt
         FROM catalog_returns cr
         UNION ALL
         SELECT wr.wr_item_sk AS ir_item_sk, wr.wr_return_quantity AS ir_return_quantity, wr.wr_return_amt AS ir_return_amt
         FROM web_returns wr) ir
    GROUP BY 
        ir.ir_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.customer_category,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT it.rs_item_sk) AS unique_items_sold,
    COALESCE(SUM(ir.total_returned_quantity), 0) AS total_items_returned,
    CASE 
        WHEN MAX(ir.avg_return_amount) > 0 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_rate_category
FROM 
    CustomerSegmentation cs
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.ws_customer_sk
LEFT JOIN 
    ItemReturnStats ir ON ir.ir_item_sk = rs.ws_item_sk
WHERE 
    (cs.cd_purchase_estimate BETWEEN 100 AND 500 OR cs.cd_purchase_estimate IS NULL) 
    AND EXISTS (SELECT 1 FROM store s WHERE s.s_state = 'NY')
GROUP BY 
    cs.c_customer_sk, cs.customer_category
HAVING 
    COUNT(DISTINCT rs.ws_item_sk) > 5 AND total_sales > 1000
ORDER BY 
    total_sales DESC, customer_category;
