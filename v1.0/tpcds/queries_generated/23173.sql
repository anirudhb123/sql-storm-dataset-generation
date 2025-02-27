
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) as rnk
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_items
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_returns,
        cs.total_returned_items,
        ROW_NUMBER() OVER (ORDER BY cs.total_returned_items DESC) as rn
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_returns > 0
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    MAX(ir.inv_quantity_on_hand) AS max_inventory,
    COALESCE(SUM(CASE WHEN r.rnk = 1 THEN 1 ELSE 0 END), 0) AS latest_return_count,
    CASE 
        WHEN SUM(ws.ws_quantity) IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    inventory ir ON r.sr_item_sk = ir.inv_item_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
HAVING 
    MAX(ir.inv_quantity_on_hand) IS NOT NULL
    OR COUNT(DISTINCT ws.ws_order_number) > 2
ORDER BY 
    sales_status, latest_return_count DESC;
