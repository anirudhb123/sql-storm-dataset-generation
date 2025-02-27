
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_count,
        SUM(CASE WHEN cd.cd_dep_college_count > 0 THEN 1 ELSE 0 END) AS college_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesStats AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458833 AND 2458838 -- arbitrary date range
),
InventoryStats AS (
    SELECT 
        inv.warehouse_sk,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
)
SELECT 
    cs.ca_state,
    cs.total_customers,
    cs.avg_purchase_estimate,
    ss.total_sales,
    ss.total_discount,
    ss.total_orders,
    is.total_items,
    is.total_quantity
FROM 
    customer_address cs
JOIN 
    CustomerStats c ON cs.ca_address_sk = c.total_customers -- assuming customer_address has a logical relationship with CustomerStats
JOIN 
    SalesStats ss ON 1=1 -- Cross join for simplicity
JOIN 
    InventoryStats is ON 1=1 -- Cross join for simplicity
WHERE 
    cs.ca_state IN ('CA', 'NY', 'TX') -- filtering for specific states
ORDER BY 
    cs.ca_state;
