
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_birth_year,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv2.inv_date_sk) FROM inventory inv2)
    GROUP BY 
        inv.inv_item_sk
),
ReturnStatistics AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
    GROUP BY 
        sr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    MAX(ic.total_quantity) AS available_stock,
    COALESCE(rs.total_returns, 0) AS total_returned,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity
FROM 
    RankedCustomers c
LEFT JOIN 
    InventoryCheck ic ON c.rn = 1  -- Prioritizing the latest ranked customer (the oldest based on birth year)
LEFT JOIN 
    ReturnStatistics rs ON ic.inv_item_sk = (SELECT MIN(inv_item_sk) FROM InventoryCheck) -- Joining the item with the least stock
WHERE 
    c.cd_birth_year IS NOT NULL
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, rs.total_returns, rs.total_returned_amount, rs.total_returned_quantity
HAVING 
    (COALESCE(rs.total_returns, 0) > 0 OR MAX(ic.total_quantity) > 10)
ORDER BY 
    available_stock DESC, total_returned DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
