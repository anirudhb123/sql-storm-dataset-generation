
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_tax) AS total_web_return_tax
    FROM
        web_returns wr
    JOIN
        customer c ON wr.returning_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
),
StoreSales AS (
    SELECT
        s_store_sk,
        SUM(ss_net_paid) AS total_store_sales,
        AVG(ss_sales_price) AS avg_sales_price
    FROM
        store_sales ss
    GROUP BY
        s_store_sk
),
Promotions AS (
    SELECT
        p.p_promo_sk,
        COUNT(DISTINCT ws_order_number) AS promotion_sales_count,
        SUM(ws_net_paid_inc_tax) AS promotion_total_sales
    FROM
        web_sales ws
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        p.p_discount_active = 'Y'
    GROUP BY
        p.p_promo_sk
),
InventoryCheck AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    c.c_customer_id,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(cr.web_return_count, 0) AS web_return_count,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    COALESCE(ss.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(pm.promotion_sales_count, 0) AS promo_sales_count,
    COALESCE(pm.promotion_total_sales, 0) AS promo_total_sales,
    CASE
        WHEN ic.total_quantity IS NULL THEN 'No Inventory'
        ELSE CAST(ic.total_quantity AS VARCHAR)
    END AS inventory_status
FROM
    customer c
LEFT JOIN
    CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN
    StoreSales ss ON ss.s_store_sk = (
        SELECT s_store_sk FROM store s WHERE s.s_number_employees > 50 LIMIT 1
    )
LEFT JOIN
    Promotions pm ON pm.p_promo_sk IN (
        SELECT DISTINCT p.p_promo_sk FROM promotion p WHERE p.p_channel_email = 'Y'
    )
LEFT JOIN
    InventoryCheck ic ON ic.inv_item_sk = (
        SELECT DISTINCT i_item_sk FROM item WHERE i_current_price > 100 LIMIT 1
    )
WHERE
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY
    total_return_amt DESC, total_store_sales DESC;
