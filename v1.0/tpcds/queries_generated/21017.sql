
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.customer_sk, 
        sr.returned_quantity, 
        sr.return_amt, 
        ca.state AS return_state
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.customer_sk = c.customer_sk
    JOIN 
        customer_address ca ON c.current_addr_sk = ca.address_sk
    WHERE 
        sr.returned_date_sk > 10000 AND
        (ca.state IN ('CA', 'TX') OR ca.state IS NULL)
), 
AggregateReturns AS (
    SELECT 
        return_state, 
        SUM(returned_quantity) AS total_returned_qty, 
        SUM(return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY return_state ORDER BY SUM(returned_quantity) DESC) AS return_rank
    FROM 
        CustomerReturns
    GROUP BY 
        return_state
    HAVING 
        SUM(return_amt) > 100
),
InventoryStatus AS (
    SELECT 
        inv.warehouse_sk, 
        SUM(CASE WHEN inv_quantity_on_hand IS NULL THEN 0 ELSE inv_quantity_on_hand END) AS total_quantity_on_hand,
        COUNT(DISTINCT i.item_id) AS unique_item_count
    FROM 
        inventory inv
    JOIN 
        item i ON inv.item_sk = i.item_sk
    WHERE 
        inv.inv_date_sk BETWEEN 10000 AND 20000
    GROUP BY 
        inv.warehouse_sk
    HAVING 
        total_quantity_on_hand > 0
)
SELECT 
    ar.return_state,
    ar.total_returned_qty,
    ar.total_return_amt,
    inv.total_quantity_on_hand,
    inv.unique_item_count,
    COALESCE(inv.total_quantity_on_hand, 0) - COALESCE(ar.total_returned_qty, 0) AS adjusted_quantity
FROM 
    AggregateReturns ar
FULL OUTER JOIN 
    InventoryStatus inv ON ar.return_state = inv.warehouse_sk
WHERE 
    (ar.return_rank < 5 OR ar.return_rank IS NULL)
    AND (inv.unique_item_count > 10 OR inv.unique_item_count IS NULL)
ORDER BY 
    ar.total_returned_qty DESC NULLS LAST, 
    inv.total_quantity_on_hand ASC NULLS FIRST;
