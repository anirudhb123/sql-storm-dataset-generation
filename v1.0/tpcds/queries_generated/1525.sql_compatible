
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
        AND ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws.ws_item_sk
), HighProfitItems AS (
    SELECT 
        ir.ir_item_sk,
        ir.ir_qty,
        ir.ir_ext_sales_price
    FROM 
        (SELECT 
            cs.cs_item_sk AS ir_item_sk,
            SUM(cs.cs_quantity) AS ir_qty,
            SUM(cs.cs_ext_sales_price) AS ir_ext_sales_price
         FROM 
            catalog_sales cs
         GROUP BY 
            cs.cs_item_sk
        ) ir
    WHERE 
        ir.ir_ext_sales_price > 2000
), CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_return_quantity) AS total_returned_qty
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(hp.ir_qty), 0) AS total_high_profit_sales,
    COALESCE(cr.total_returned_qty, 0) AS total_customer_returns,
    SUM(r.total_sales) AS total_online_sales,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales r ON r.ws_item_sk IN (SELECT ir.ir_item_sk FROM HighProfitItems ir)
LEFT JOIN 
    CustomerReturns cr ON cr.sr_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(c.c_customer_sk) > 10
ORDER BY 
    total_online_sales DESC;
