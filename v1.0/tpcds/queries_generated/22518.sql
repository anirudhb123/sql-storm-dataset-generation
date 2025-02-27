
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 0
),
LatestPromotions AS (
    SELECT 
        p.p_promo_id,
        MAX(p.p_start_date_sk) AS latest_start_date
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
),
InventoryDetails AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY 
        inv.inv_item_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(ws_total.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss_total.total_store_sales, 0) AS total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss_total.total_store_sales, 0) AS grand_total,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cs.total_web_sales, 0) + COALESCE(ss_total.total_store_sales, 0) DESC) AS customer_rank
    FROM 
        CustomerSales cs 
    FULL OUTER JOIN 
        (SELECT 
            ss.ss_customer_sk,
            SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
        FROM 
            store_sales ss
        GROUP BY 
            ss.ss_customer_sk) AS ss_total 
    ON 
        cs.c_customer_id = ss_total.ss_customer_sk
    LEFT JOIN 
        LatestPromotions lp ON lp.latest_start_date > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE)
)
SELECT 
    s.c_customer_id,
    s.grand_total,
    CASE 
        WHEN s.grand_total >= 1000 THEN 'VIP' 
        WHEN s.grand_total >= 500 AND s.grand_total < 1000 THEN 'Regular' 
        ELSE 'New' 
    END AS customer_type,
    COALESCE(id.total_quantity, 0) AS inventory_level
FROM 
    SalesSummary s
LEFT JOIN 
    InventoryDetails id ON id.inv_item_sk = (SELECT i.i_item_sk FROM item i ORDER BY RANDOM() LIMIT 1)
WHERE 
    s.grand_total IS NOT NULL
ORDER BY 
    s.grand_total DESC
LIMIT 50;
