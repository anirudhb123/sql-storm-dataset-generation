
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
AggregatedReturns AS (
    SELECT
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn <= 5
    GROUP BY 
        rr.sr_item_sk
),
TopStores AS (
    SELECT 
        ss_store_sk, 
        COUNT(DISTINCT ss_ticket_number) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    HAVING 
        COUNT(DISTINCT ss_ticket_number) >= 100
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
Combined AS (
    SELECT 
        ar.sr_item_sk, 
        ar.total_returns, 
        ar.return_count, 
        ti.total_quantity,
        ts.total_sales
    FROM 
        AggregatedReturns ar
    LEFT JOIN 
        ItemInventory ti ON ar.sr_item_sk = ti.inv_item_sk
    LEFT JOIN 
        TopStores ts ON ts.ss_store_sk = (
            SELECT 
                s_store_sk
            FROM 
                store
            ORDER BY 
                RANDOM()
            LIMIT 1
        )
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cb.total_returns, 0) AS total_returns,
    COALESCE(cb.return_count, 0) AS return_count,
    cb.total_quantity,
    COUNT(DISTINCT wo.wp_web_page_id) AS web_page_views
FROM 
    customer c
LEFT JOIN 
    Combined cb ON c.c_customer_sk = cb.sr_item_sk
LEFT JOIN 
    web_page wo ON wo.wp_customer_sk = c.c_customer_sk
WHERE 
    cb.total_quantity > 10
    AND (c.c_birth_month = EXTRACT(MONTH FROM DATE '2002-10-01') OR c.c_birth_month IS NULL)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cb.total_returns, cb.return_count, cb.total_quantity
ORDER BY 
    c.c_customer_id DESC
LIMIT 100;
