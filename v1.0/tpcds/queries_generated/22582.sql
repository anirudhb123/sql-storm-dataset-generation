
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
), 
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price - ss.ss_ext_discount_amt) AS total_sales,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
TopStores AS (
    SELECT 
        w.w_warehouse_sk, 
        w.w_warehouse_name,
        COALESCE(ss.total_sales, 0) AS sales,
        COALESCE(ss.transaction_count, 0) AS count,
        COALESCE(wi.total_inventory, 0) AS inventory,
        DENSE_RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
    FROM 
        warehouse w
    LEFT JOIN 
        StoreSalesSummary ss ON w.w_warehouse_sk = ss.ss_store_sk
    LEFT JOIN 
        WarehouseInventory wi ON w.w_warehouse_sk = wi.inv_warehouse_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ts.warehouse_sk,
    ts.warehouse_name,
    ts.sales,
    ts.count AS transaction_count,
    ts.inventory,
    CASE 
        WHEN ts.sales > 0 THEN 
            ROUND((ts.sales - (ts.sales * 0.1)) / NULLIF(ts.count, 0), 2) 
        ELSE 
            NULL 
    END AS avg_sales_per_transaction,
    CASE
        WHEN ci.gender_rank = 1 THEN 'Top Gender Buyer'
        ELSE 'Regular Buyer'
    END AS buyer_category
FROM 
    CustomerInfo ci
INNER JOIN 
    TopStores ts ON ci.c_customer_sk = (SELECT 
                                             cr_returning_customer_sk 
                                         FROM 
                                             catalog_returns 
                                         WHERE 
                                             cr_return_paid > (SELECT AVG(cr_return_paid) FROM catalog_returns) 
                                         LIMIT 1)
WHERE 
    ts.sales > 1000 
ORDER BY 
    ts.sales DESC, ci.c_last_name ASC
LIMIT 50;
