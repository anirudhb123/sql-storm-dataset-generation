
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
),
HighReturnItems AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_return_quantity,
        SUM(rr.sr_return_amt) AS total_return_amt
    FROM 
        RankedReturns rr
    WHERE 
        rr.rnk = 1
    GROUP BY 
        rr.sr_item_sk
    HAVING 
        SUM(rr.sr_return_quantity) > 10
),
CustomerPurchaseInsights AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
ItemPerformance AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(hr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(hr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN hr.total_return_quantity > 0 THEN 'High Return'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        item i
    LEFT JOIN 
        HighReturnItems hr ON i.i_item_sk = hr.sr_item_sk
)
SELECT 
    cpi.c_customer_id,
    ip.i_item_id,
    ip.i_item_desc,
    SUM(ip.total_return_quantity) AS total_returns,
    SUM(ip.total_return_amt) AS total_return_amount,
    COUNT(cpi.total_orders) AS customer_orders,
    SUM(cpi.total_spent) AS customer_total_spent,
    CASE 
        WHEN SUM(ip.total_return_quantity) > 10 THEN 'Frequent Returner'
        ELSE 'Infrequent Returner'
    END AS returner_category
FROM 
    CustomerPurchaseInsights cpi
JOIN 
    ItemPerformance ip ON cpi.total_orders > 5
GROUP BY 
    cpi.c_customer_id, ip.i_item_id, ip.i_item_desc
ORDER BY 
    total_returns DESC, customer_total_spent DESC
LIMIT 100
OFFSET 50;
