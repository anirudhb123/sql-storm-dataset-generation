
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IS NOT NULL 
        AND ws_net_profit > 0
    GROUP BY 
        ws_item_sk
),
CustReturnStats AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        cr_returning_customer_sk
),
InventoryLevels AS (
    SELECT 
        inv_item_sk,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand,
        MAX(inv_quantity_on_hand) AS max_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
AddressCount AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
)
SELECT 
    C.c_customer_id,
    CA.ca_city,
    ADD.address_count,
    COALESCE(S.total_quantity, 0) AS web_sales_quantity,
    COALESCE(S.total_net_profit, 0) AS web_sales_net_profit,
    COALESCE(R.total_returns, 0) AS total_catalog_returns,
    COALESCE(R.total_return_amount, 0) AS total_return_amount,
    I.avg_quantity_on_hand,
    I.max_quantity_on_hand
FROM 
    customer C 
LEFT JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    SalesCTE S ON C.c_customer_sk = S.ws_item_sk
LEFT JOIN 
    CustReturnStats R ON C.c_customer_sk = R.cr_returning_customer_sk
LEFT JOIN 
    InventoryLevels I ON S.ws_item_sk = I.inv_item_sk
JOIN 
    AddressCount ADD ON CA.ca_state = ADD.ca_state
WHERE 
    C.c_birth_year > (SELECT AVG(d_year) FROM date_dim WHERE d_current_year = 'Y')
    AND (CA.ca_city IS NOT NULL OR CA.ca_city LIKE '%City%')
    AND S.sales_rank = 1
ORDER BY 
    web_sales_net_profit DESC, 
    total_return_amount ASC
LIMIT 100
OFFSET 10;
