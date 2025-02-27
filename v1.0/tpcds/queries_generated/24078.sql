
WITH RevenueData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        r.total_revenue,
        r.order_count,
        r.revenue_rank
    FROM 
        RevenueData r
    JOIN 
        customer c ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.revenue_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd.*,
        CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE (SELECT ib_upper_bound FROM income_band ib WHERE ib.ib_income_band_sk = cd.cd_demo_sk) 
        END AS income_band
    FROM 
        household_demographics cd
),
InventoryCheck AS (
    SELECT 
        i.i_item_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    JOIN 
        item itm ON itm.i_item_sk = i.inv_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    tc.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ic.i_item_id,
    ic.total_inventory,
    COALESCE(tc.total_revenue, 0) AS total_revenue
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerDemographics cd ON tc.c_customer_id = cd.cd_demo_sk
LEFT JOIN 
    InventoryCheck ic ON ic.i_item_id = (
        SELECT i.i_item_id 
        FROM item i 
        WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item)
        ORDER BY i.i_current_price DESC 
        LIMIT 1
    )
WHERE 
    (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NULL)
ORDER BY 
    total_revenue DESC, 
    cd.cd_birth_month DESC NULLS LAST;
