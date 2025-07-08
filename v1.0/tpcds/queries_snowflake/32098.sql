
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS Level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ch.Level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (ch.Level * 500)
), 
ReturnsData AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS Total_Returned_Quantity,
        SUM(wr.wr_return_amt) AS Total_Returned_Amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk, 
        wr.wr_item_sk
), 
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS Total_Sold_Quantity,
        SUM(ws.ws_net_paid) AS Total_Sold_Amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
FinalData AS (
    SELECT 
        cd.c_customer_sk,
        SUM(sd.Total_Sold_Quantity - rd.Total_Returned_Quantity) AS Net_Sales,
        COUNT(sd.Total_Sold_Quantity) AS Sale_Count
    FROM 
        CustomerHierarchy cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_item_sk
    LEFT JOIN 
        ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
    GROUP BY 
        cd.c_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.Net_Sales,
    f.Sale_Count,
    CASE 
        WHEN f.Net_Sales IS NULL THEN 'No Sales'
        WHEN f.Net_Sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS Customer_Category,
    ROW_NUMBER() OVER (ORDER BY f.Net_Sales DESC) AS Sales_Rank
FROM 
    FinalData f
WHERE 
    f.Net_Sales > 0
ORDER BY 
    f.Net_Sales DESC;
