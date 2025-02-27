
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2458496 
), 
CustomerStats AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
AddressStats AS (
    SELECT
        ca.ca_state,
        COUNT(ca.ca_address_sk) AS address_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.order_count,
    cs.total_spent,
    as.ca_state,
    as.address_count,
    as.avg_purchase_estimate,
    COALESCE(cte.ws_quantity, 0) AS latest_quantity,
    SUM(CASE WHEN cs.total_spent > 1000 THEN 1 ELSE 0 END) OVER () AS high_spenders_count
FROM 
    CustomerStats cs
JOIN 
    AddressStats as ON cs.cd_gender IS NOT NULL
LEFT JOIN 
    SalesCTE cte ON cs.ws_item_sk = cte.ws_item_sk AND cte.rn = 1
WHERE 
    cs.total_spent IS NOT NULL 
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
