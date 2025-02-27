
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amt,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.web_site_id, ws.ws_item_sk
),
SalesReasons AS (
    SELECT
        ws.ws_item_sk,
        COALESCE(sr_reason.r_reason_desc, 'No Reason') AS reason_desc,
        SUM(ws.ws_quantity) AS return_quantity,
        SUM(ws.ws_ext_sales_price) AS return_amt_inc_tax
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        reason sr_reason ON wr.wr_reason_sk = sr_reason.r_reason_sk
    GROUP BY 
        ws.ws_item_sk, sr_reason.r_reason_desc
)
SELECT 
    s.web_site_id,
    s.ws_item_sk,
    s.total_sales_quantity,
    s.total_sales_amt,
    COALESCE(r.return_quantity, 0) AS return_quantity,
    COALESCE(r.return_amt_inc_tax, 0) AS return_amt_inc_tax
FROM 
    RankedSales s
LEFT JOIN 
    SalesReasons r ON s.ws_item_sk = r.ws_item_sk
WHERE 
    s.sales_rank <= 5
ORDER BY 
    s.web_site_id, s.total_sales_amt DESC;
