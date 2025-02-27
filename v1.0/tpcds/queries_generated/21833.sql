
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > (
            SELECT AVG(SUM(ws2.ws_net_paid_inc_tax)) 
            FROM web_sales ws2 
            GROUP BY ws2.ws_bill_customer_sk
        )
),
ItemSales AS (
    SELECT 
        is_item.i_item_id,
        COALESCE(SUM(cs.cs_quantity), 0) AS catalog_sales,
        COALESCE(SUM(ws.ws_quantity), 0) AS web_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS store_sales
    FROM 
        item is_item
    LEFT JOIN 
        catalog_sales cs ON is_item.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        web_sales ws ON is_item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_sales ss ON is_item.i_item_sk = ss.ss_item_sk
    GROUP BY 
        is_item.i_item_id
),
BestSellingItems AS (
    SELECT 
        i_item_id,
        catalog_sales + web_sales + store_sales AS total_sales
    FROM 
        ItemSales
)
SELECT 
    r.returned_item_id,
    r.return_quantity,
    r.return_amt,
    c.customer_id,
    abc.item_id,
    abc.total_sales
FROM 
    RankedReturns r
JOIN 
    Inventory inv ON r.sr_item_sk = inv.inv_item_sk
JOIN 
    Customer c ON c.c_customer_sk = (
        SELECT 
            sr_customer_sk 
        FROM 
            store_returns 
        WHERE 
            sr_item_sk = r.sr_item_sk 
            AND sr_return_quantity = r.return_quantity
        LIMIT 1
    )
JOIN 
    BestSellingItems abc ON inv.inv_item_sk = abc.i_item_id
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND r.return_amt > 100
    AND EXISTS (
        SELECT 1 
        FROM HighValueCustomers hvc 
        WHERE hvc.c_customer_id = c.c_customer_id
    )
ORDER BY 
    r.return_amt DESC, c.customer_id ASC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM store_returns) % 50;
