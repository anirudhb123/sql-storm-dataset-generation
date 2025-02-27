
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        sr_store_sk,
        CASE 
            WHEN sr_return_quantity > 10 THEN 'High Return'
            WHEN sr_return_quantity BETWEEN 5 AND 10 THEN 'Medium Return'
            ELSE 'Low Return'
        END AS Return_Category
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
),
DailySales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS Total_Sales,
        SUM(ws_sales_price * ws_quantity) AS Total_Sales_Amount
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
ReturnAnalytics AS (
    SELECT 
        d.d_date_id,
        c.ca_country,
        SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_return_quantity ELSE 0 END) AS Total_Returned,
        SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_return_amt_inc_tax ELSE 0 END) AS Total_Return_Amount,
        SUM(COALESCE(cs.cs_quantity, 0)) AS Total_Units_Sold,
        SUM(COALESCE(cs.cs_sales_price * cs.cs_quantity, 0)) AS Total_Sales_Amount,
        COALESCE(AVG(cr.cr_return_amount / NULLIF(cs.cs_net_paid_inc_tax, 0)), 0) AS Return_Percentage
    FROM 
        date_dim d
    LEFT JOIN 
        catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN 
        CustomerReturns c ON c.sr_item_sk = cr.cr_item_sk
    GROUP BY 
        d.d_date_id, c.ca_country
)
SELECT 
    d.d_date_id,
    COALESCE(c.ca_country, 'Unknown') AS Country,
    COALESCE(r.Total_Returned, 0) AS Total_Returned,
    COALESCE(r.Total_Return_Amount, 0) AS Total_Return_Amount,
    COALESCE(r.Total_Units_Sold, 0) AS Total_Units_Sold,
    COALESCE(r.Total_Sales_Amount, 0) AS Total_Sales_Amount,
    COALESCE(r.Return_Percentage, 0) AS Return_Percentage,
    COUNT(DISTINCT CASE WHEN r.Total_Returned > 0 THEN r.Total_Returned END) AS Num_Returning_Items
FROM 
    date_dim d
LEFT JOIN 
    ReturnAnalytics r ON r.d_date_id = d.d_date_id
LEFT JOIN 
    customer_address c ON c.ca_address_sk = (
        SELECT 
            ca_address_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk IN (SELECT c.c_customer_sk FROM customer WHERE c.c_current_addr_sk = c.ca_address_sk LIMIT 1) 
        LIMIT 1
    )
WHERE 
    d.d_date BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY 
    d.d_date_id, c.ca_country
ORDER BY 
    d.d_date_id DESC, 
    Total_Return_Amount DESC;
