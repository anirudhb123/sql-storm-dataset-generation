
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS Total_Returns,
        SUM(sr_return_amt_inc_tax) AS Total_Return_Value,
        COUNT(DISTINCT sr_item_sk) AS Unique_Items_Returned
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
IncomeBandAnalysis AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS Total_Customers,
        AVG(h.hd_dep_count) AS Avg_Dependency_Count
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_income_band_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_sales_price) AS Total_Sales,
        SUM(ws_coupon_amt) AS Total_Coupons_Redeemed,
        COUNT(DISTINCT ws_order_number) AS Unique_Orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_bill_cdemo_sk
),
ReturnRate AS (
    SELECT 
        c.c_customer_id,
        COALESCE(CAST(cr.Total_Returns AS DECIMAL) / NULLIF(ss.Unique_Orders, 0), 0) AS Return_Rate
    FROM 
        CustomerReturns cr
    JOIN 
        SalesSummary ss ON cr.c_customer_id = ss.ws_bill_cdemo_sk
)
SELECT 
    cr.c_customer_id,
    cr.Total_Returns,
    cr.Total_Return_Value,
    ia.hd_income_band_sk,
    ia.Total_Customers,
    ia.Avg_Dependency_Count,
    rr.Return_Rate
FROM 
    CustomerReturns cr
LEFT JOIN 
    IncomeBandAnalysis ia ON ia.hd_income_band_sk IN (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk = cr.c_customer_id)
LEFT JOIN 
    ReturnRate rr ON rr.c_customer_id = cr.c_customer_id
WHERE 
    cr.Total_Returns > 0 OR rr.Return_Rate > 0
ORDER BY 
    Return_Rate DESC, Total_Return_Value DESC
LIMIT 100;
