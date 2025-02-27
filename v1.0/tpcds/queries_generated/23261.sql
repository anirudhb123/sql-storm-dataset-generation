
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amount) AS total_return_amount
    FROM 
        customer c 
    INNER JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        crs.c_customer_sk, 
        crs.return_count, 
        crs.total_return_amount
    FROM 
        CustomerReturnStats crs
    WHERE 
        crs.total_return_amount > (SELECT AVG(total_return_amount) FROM CustomerReturnStats)
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
SalesByReturn AS (
    SELECT 
        ir.item_sk,
        COALESCE(NULLIF(is.total_sold, 0), 1) AS adjusted_sold,
        ir.total_return_quantity,
        CASE 
            WHEN ir.total_return_quantity IS NULL THEN 0 
            ELSE ir.total_return_quantity / COALESCE(NULLIF(is.total_sold, 0), 1)
        END AS return_ratio
    FROM 
        (SELECT 
            sr_item_sk AS item_sk,
            SUM(sr_return_quantity) AS total_return_quantity
        FROM 
            RankedReturns
        WHERE 
            rnk = 1
        GROUP BY 
            sr_item_sk) ir
    LEFT JOIN 
        ItemSales is ON ir.item_sk = is.ws_item_sk
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    sr.return_ratio,
    CASE 
        WHEN sr.return_ratio > 0.5 THEN 'High Return'
        WHEN sr.return_ratio BETWEEN 0.2 AND 0.5 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    HighReturnCustomers hrc
JOIN 
    customer c ON hrc.c_customer_sk = c.c_customer_sk
JOIN 
    SalesByReturn sr ON sr.item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
ORDER BY 
    return_category DESC, 
    return_ratio DESC;
