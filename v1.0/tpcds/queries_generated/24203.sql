
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_customer_sk
),
ReturningItems AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 0
),
Combos AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sold,
        COALESCE(SUM(ri.total_returned), 0) AS total_returned_quantity,
        (SUM(cs.cs_quantity) - COALESCE(SUM(ri.total_returned), 0)) AS net_sales
    FROM 
        catalog_sales cs
    LEFT JOIN 
        ReturningItems ri ON cs.cs_item_sk = ri.sr_item_sk
    GROUP BY 
        cs.cs_item_sk
    HAVING 
        net_sales > 0
    ORDER BY 
        net_sales DESC
)
SELECT 
    c.c_customer_id,
    rs.total_net_profit,
    cb.total_sold,
    cb.total_returned_quantity,
    cb.net_sales,
    (CASE 
         WHEN cb.net_sales IS NULL THEN 'No Sales'
         WHEN cb.net_sales >= 1000 THEN 'High Sales'
         ELSE 'Regular Sales'
     END) AS sales_category
FROM 
    RankedCustomerSales rs
JOIN 
    customer c ON rs.c_customer_id = c.c_customer_id
LEFT JOIN 
    Combos cb ON cb.cs_item_sk = 
        (SELECT 
            cs.cs_item_sk 
         FROM 
            catalog_sales cs 
         WHERE 
            cs.cs_bill_customer_sk = c.c_customer_sk 
         ORDER BY 
            cs.cs_sales_price DESC 
         LIMIT 1)
WHERE 
    (rs.profit_rank = 1 OR Rs.total_net_profit IS NULL)
ORDER BY 
    rs.total_net_profit DESC NULLS LAST;
