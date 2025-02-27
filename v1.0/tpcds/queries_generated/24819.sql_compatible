
WITH RankedReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount,
        RANK() OVER (PARTITION BY cr.cr_item_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS rank_return
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > (
            SELECT AVG(total_spent) FROM (
                SELECT SUM(ws2.ws_net_paid) AS total_spent
                FROM web_sales ws2
                GROUP BY ws2.ws_bill_customer_sk
            ) AS avg_customers
        )
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.total_sold,
    id.total_sales,
    hr.return_count,
    hr.total_return_amount,
    hvc.total_spent AS customer_spending,
    hvc.order_count
FROM 
    ItemDetails id
LEFT JOIN 
    RankedReturns hr ON id.i_item_sk = hr.cr_item_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_customer_sk IN (
        SELECT DISTINCT ws.ws_ship_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = id.i_item_sk
    )
WHERE 
    (hr.return_count IS NULL OR hr.return_count < 5) AND
    (hvc.total_spent IS NOT NULL OR hvc.order_count > 1)
ORDER BY 
    id.total_sales DESC, 
    hr.return_count ASC NULLS LAST;
