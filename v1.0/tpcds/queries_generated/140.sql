
WITH TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_net_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450018 AND 2450616 -- Some date range for benchmarking
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ti.i_item_sk,
        ti.i_item_id,
        ti.i_product_name,
        ts.total_net_sales,
        ts.total_orders,
        ts.avg_net_sales
    FROM 
        item ti 
    JOIN 
        TotalSales ts 
    ON 
        ti.i_item_sk = ts.ws_item_sk 
    WHERE 
        ts.rank_sales <= 10
)
SELECT 
    t.I_ITEM_ID,
    t.I_PRODUCT_NAME,
    COALESCE(t.total_net_sales, 0) AS Total_Net_Sales,
    COALESCE(t.total_orders, 0) AS Total_Orders,
    COALESCE(t.avg_net_sales, 0) AS Avg_Net_Sales,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT w.ws_order_number) AS Web_Orders,
    SUM(w.ws_net_paid) AS Web_Net_Sales
FROM 
    TopItems t
LEFT JOIN 
    web_sales w ON t.i_item_sk = w.ws_item_sk
LEFT JOIN 
    customer ci ON w.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    ci.c_birth_year IS NOT NULL 
    AND (ci.c_birth_month < 7 OR ci.c_birth_month IS NULL)
GROUP BY 
    t.I_ITEM_ID, t.I_PRODUCT_NAME, ci.cd_gender, ci.cd_marital_status
ORDER BY 
    Total_Net_Sales DESC;
