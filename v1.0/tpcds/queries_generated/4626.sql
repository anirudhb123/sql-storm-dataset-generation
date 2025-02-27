
WITH CustomerReturns AS (
    SELECT 
        sr.rs_item_sk AS Item_SK,
        SUM(sr_return_quantity) AS Total_Returned,
        SUM(sr_return_amt_inc_tax) AS Total_Return_Amount,
        SUM(sr_net_loss) AS Total_Net_Loss
    FROM 
        store_returns sr
    WHERE 
        sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk AS Item_SK,
        SUM(ws_quantity) AS Total_Sold,
        SUM(ws_net_profit) AS Total_Profit,
        COUNT(DISTINCT ws_order_number) AS Unique_Orders
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CombinedInfo AS (
    SELECT 
        ci.Item_SK,
        COALESCE(Total_Sold, 0) AS Total_Sold,
        COALESCE(Total_Returned, 0) AS Total_Returned,
        COALESCE(Total_Return_Amount, 0) AS Total_Return_Amount,
        COALESCE(Total_Net_Loss, 0) AS Total_Net_Loss,
        COALESCE(Total_Profit, 0) AS Total_Profit,
        Unique_Orders
    FROM 
        (SELECT DISTINCT Item_SK FROM CustomerReturns 
         UNION 
         SELECT DISTINCT Item_SK FROM SalesInfo) ci
    LEFT JOIN CustomerReturns cr ON ci.Item_SK = cr.Item_SK
    LEFT JOIN SalesInfo si ON ci.Item_SK = si.Item_SK
)
SELECT 
    c.i_item_id,
    c.i_item_desc,
    ci.Total_Sold,
    ci.Total_Returned,
    ci.Total_Return_Amount,
    ci.Total_Net_Loss,
    ci.Total_Profit,
    ci.Unique_Orders,
    (CASE 
        WHEN ci.Total_Sold = 0 THEN NULL 
        ELSE (ci.Total_Returned::decimal / ci.Total_Sold) * 100 
     END) AS Return_Rate_Percentage
FROM 
    item c
JOIN 
    CombinedInfo ci ON c.i_item_sk = ci.Item_SK
WHERE 
    ci.Total_Returned > 0 OR ci.Total_Sold > 0
ORDER BY 
    Return_Rate_Percentage DESC NULLS LAST
LIMIT 10;
