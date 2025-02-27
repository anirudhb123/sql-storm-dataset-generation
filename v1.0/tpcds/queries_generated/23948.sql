
WITH RecentSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        COALESCE(NULLIF(ws.ws_ship_date_sk, 0), 1) AS Effective_Ship_Date, 
        SUM(ws.ws_sales_price) AS Total_Sales_Amount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1970 
        AND c.c_birth_year <= 2000
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk, ws.ws_sold_date_sk
), AggregateReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_ticket_number) AS Total_Returns,
        SUM(sr_return_amt) AS Return_Amount,
        SUM(sr_return_quantity) AS Return_Quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id,
        COALESCE(ib.ib_upper_bound, 0) AS Income_Band_Upper_Bound,
        COALESCE(ib.ib_lower_bound, 0) AS Income_Band_Lower_Bound
    FROM 
        item i
    LEFT JOIN 
        income_band ib ON ib.ib_income_band_sk = (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk = i.i_item_sk % 1000)
)
SELECT 
    id.i_item_id,
    id.Income_Band_Upper_Bound,
    id.Income_Band_Lower_Bound,
    COALESCE(rs.Total_Sales_Amount, 0) AS Total_Sales,
    COALESCE(ar.Total_Returns, 0) AS Total_Returns,
    COALESCE(ar.Return_Amount, 0) AS Total_Return_Amount,
    CASE 
        WHEN COALESCE(ar.Return_Quantity, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS Return_Status,
    CASE 
        WHEN rs.rn = 1 THEN 'Latest Sale'
        ELSE 'Previous Sale'
    END AS Sale_Status
FROM 
    ItemDetails id
LEFT JOIN 
    RecentSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.rn = 1
LEFT JOIN 
    AggregateReturns ar ON id.i_item_sk = ar.sr_item_sk
WHERE 
    (id.Income_Band_Upper_Bound IS NOT NULL OR id.Income_Band_Lower_Bound IS NOT NULL)
    AND 
    NOT EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = id.i_item_sk AND ss.ss_sales_price < 0)
ORDER BY 
    id.i_item_id;
