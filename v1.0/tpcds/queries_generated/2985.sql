
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) as Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459644 AND 2459648  -- example date range
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Order_Count,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS Unique_Customers
    FROM 
        item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS Total_Customers,
        AVG(cd.cd_purchase_estimate) AS Avg_Purchase_Estimate,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS Male_Customers,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS Female_Customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        rs.Rank,
        ss.Total_Sales,
        cs.Total_Customers,
        cs.Avg_Purchase_Estimate
    FROM 
        RankedSales rs
    JOIN 
        SalesSummary ss ON rs.ws_item_sk = ss.i_item_id
    JOIN 
        CustomerStats cs ON cs.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL LIMIT 1)
    WHERE 
        rs.Rank <= 5
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.Total_Sales,
    ti.Total_Customers,
    ti.Avg_Purchase_Estimate,
    CASE 
        WHEN ti.Total_Sales > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS Sales_Category
FROM 
    TopItems ti
LEFT JOIN 
    reason r ON r.r_reason_sk = (SELECT r_reason_sk FROM store_returns WHERE sr_item_sk = ti.i_item_id LIMIT 1)
WHERE 
    r.r_reason_desc IS NULL OR r.r_reason_desc NOT LIKE '%damaged%'
ORDER BY 
    ti.Total_Sales DESC;
