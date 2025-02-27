
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        COUNT(*) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
Customer_Segment AS (
    SELECT 
        c.c_customer_sk,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
Returns_Stats AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_orders, 0) AS total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_qty, 0) AS total_returned_qty,
    COALESCE(rs.total_returned_amt, 0) AS total_returned_amt,
    cs.customer_segment
FROM 
    item i
LEFT JOIN 
    Sales_CTE s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    Returns_Stats rs ON i.i_item_sk = rs.sr_item_sk
INNER JOIN 
    Customer_Segment cs ON cs.c_customer_sk IN (
        SELECT DISTINCT 
            cs_ship_customer_sk 
        FROM 
            web_sales
        WHERE 
            ws_item_sk = i.i_item_sk
    )
WHERE 
    (s.total_sales IS NULL OR s.total_sales > 50)
ORDER BY 
    i.i_item_id;
