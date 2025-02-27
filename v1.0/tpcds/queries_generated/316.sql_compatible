
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
),
TotalReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_birth_year
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cp.total_spent
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases)
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.ws_sales_price, 0) AS avg_sales_price,
    COALESCE(tr.total_returned, 0) AS total_returns,
    COALESCE(inv.total_inventory, 0) AS inventory,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rank = 1
LEFT JOIN 
    TotalReturns tr ON i.i_item_sk = tr.wr_item_sk
LEFT JOIN 
    ItemInventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_spent > 1000
GROUP BY 
    i.i_item_sk, i.i_item_id, i.i_item_desc, rs.ws_sales_price, tr.total_returned, inv.total_inventory
HAVING 
    COALESCE(tr.total_returned, 0) < 5 AND COALESCE(inv.total_inventory, 0) > 10
ORDER BY 
    avg_sales_price DESC;
