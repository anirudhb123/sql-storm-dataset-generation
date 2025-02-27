
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > 1000 AND ws_quantity BETWEEN 1 AND 100
), inventory_summary AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_stock,
        CASE WHEN COUNT(inv_quantity_on_hand) = 0 THEN NULL ELSE AVG(inv_quantity_on_hand) END AS avg_stock
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
), promotion_summary AS (
    SELECT 
        p_item_sk,
        COUNT(p_promo_sk) AS promo_count,
        MAX(p_cost) AS max_cost
    FROM 
        promotion
    WHERE 
        p_discount_active = 'Y'
    GROUP BY 
        p_item_sk
), combined_data AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit,
        ISNULL(CONVERT(VARCHAR, CAST(NULLIF(rs.ws_net_profit, 0) AS VARCHAR)), 'N/A') AS profitability,
        isnull(inv.total_stock, 0) AS current_stock,
        ps.promo_count
    FROM 
        ranked_sales rs
    LEFT JOIN 
        inventory_summary inv ON rs.ws_item_sk = inv.inv_item_sk
    LEFT JOIN 
        promotion_summary ps ON rs.ws_item_sk = ps.p_item_sk
    WHERE 
        rs.rn = 1
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    coalesce(cd.c_preferred_cust_flag, 'N') AS preferred_customer,
    cf.*
FROM 
    combined_data cf
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (
        SELECT TOP 1 cu.c_current_cdemo_sk 
        FROM customer cu 
        WHERE cu.c_customer_sk IN (
            SELECT DISTINCT sr_customer_sk 
            FROM store_returns 
            WHERE sr_return_quantity > 0) 
        ORDER BY NEWID()
    )
WHERE 
    cf.current_stock < 10 AND 
    cf.promo_count > 0 
ORDER BY 
    cf.ws_net_profit DESC, 
    cd.c_last_name ASC, 
    cd.c_first_name ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
