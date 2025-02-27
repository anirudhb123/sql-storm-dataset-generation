
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rnk_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CombinedSales AS (
    SELECT 
        RANK() OVER (ORDER BY ws_ext_sales_price DESC) AS rank,
        MIN(wp.wp_type) AS web_page_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        MAX(coalesce(ir.total_returned_quantity, 0)) AS total_returned_quantity,
        MAX(CASE 
            WHEN total_returned_quantity IS NULL THEN 'No Returns'
            ELSE 'Returns Processed'
        END) AS return_status
    FROM 
        web_sales ws
    LEFT JOIN 
        RankedSales rs ON ws.ws_order_number = rs.ws_order_number
    LEFT JOIN 
        AggregateReturns ir ON ws.ws_item_sk = ir.sr_item_sk
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        wp.wp_creation_date_sk IS NOT NULL AND
        (ws.ws_net_paid IS NOT NULL OR ws.ws_net_paid_inc_tax IS NOT NULL) 
        AND (ws.ws_sales_price - ws.ws_ext_discount_amt) > 0
    GROUP BY 
        wp.wp_type
)
SELECT 
    cs.web_page_type,
    cs.total_net_paid,
    cs.total_returned_quantity,
    CASE 
        WHEN cs.total_net_paid > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS sales_value_category,
    (SELECT COUNT(*)
     FROM store s
     WHERE s.s_number_employees > (SELECT AVG(s_number_employees) FROM store)) AS avg_high_employees,
    COALESCE(NULLIF(CAST(NULLIF(cs.total_returned_quantity, 0) AS VARCHAR), '0'), 'No Returns'), 
             'Returns Exist') AS return_summary
FROM 
    CombinedSales cs
WHERE 
    sales_value_category = 'High Value'
HAVING 
    SUM(cs.total_net_paid) > 5000
ORDER BY 
    cs.total_net_paid DESC
LIMIT 10;
