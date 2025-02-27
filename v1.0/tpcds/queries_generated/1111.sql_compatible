
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS Rnk
    FROM 
        web_sales ws
    JOIN 
        customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
    LEFT JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
),
StoreReturnData AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS TotalReturns,
        SUM(sr_return_amt_inc_tax) AS TotalReturnAmount,
        SUM(sr_return_tax) AS TotalReturnTax
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity > 0 
    GROUP BY 
        sr_item_sk
),
SalesStats AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_quantity) AS TotalQuantitySold,
        SUM(sd.ws_ext_sales_price) AS TotalSales,
        COALESCE(sr.TotalReturns, 0) AS TotalReturns,
        COALESCE(sr.TotalReturnAmount, 0) AS TotalReturnAmount,
        COALESCE(sr.TotalReturnTax, 0) AS TotalReturnTax,
        (SUM(sd.ws_ext_sales_price) - COALESCE(sr.TotalReturnAmount, 0)) AS NetSales,
        (SUM(sd.ws_ext_sales_price) - COALESCE(sr.TotalReturnTax, 0)) AS NetSalesAfterTax
    FROM 
        SalesData sd
    FULL OUTER JOIN 
        StoreReturnData sr ON sd.ws_item_sk = sr.sr_item_sk
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.Rnk = 1 
    GROUP BY 
        item.i_item_id
)
SELECT 
    ss.i_item_id,
    ss.TotalQuantitySold,
    ss.TotalSales,
    ss.TotalReturns,
    ss.TotalReturnAmount,
    ss.TotalReturnTax,
    ss.NetSales,
    CASE 
        WHEN ss.NetSales < 0 THEN 'Negative Sales'
        WHEN ss.TotalQuantitySold = 0 THEN 'No Sales'
        ELSE 'Positive Sales'
    END AS SaleStatus
FROM 
    SalesStats ss
WHERE 
    ss.TotalSales > 1000 OR ss.TotalReturns > 10
ORDER BY 
    ss.TotalSales DESC;
