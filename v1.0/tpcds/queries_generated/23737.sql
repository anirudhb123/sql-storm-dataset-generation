
WITH RECURSIVE customer_revenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_revenue
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk
    HAVING 
        total_revenue > (SELECT AVG(total_revenue) FROM (SELECT 
                                                                SUM(ws_net_paid_inc_tax) AS total_revenue 
                                                            FROM 
                                                                web_sales 
                                                            GROUP BY 
                                                                ws_bill_customer_sk) AS avg_rev)
),
customer_with_address AS (
    SELECT 
        cr.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cr.total_revenue
    FROM 
        customer_revenue cr 
    LEFT JOIN 
        customer_address ca ON cr.c_customer_sk = ca.ca_address_sk
),
ranked_customers AS (
    SELECT 
        cwa.*,
        DENSE_RANK() OVER (ORDER BY cwa.total_revenue DESC) AS revenue_rank
    FROM 
        customer_with_address cwa
)
SELECT 
    r.*,
    COALESCE(r.ca_city, 'Unknown City') AS final_city,
    COALESCE(r.ca_state, 'Unknown State') AS final_state,
    CASE 
        WHEN r.revenue_rank <= 10 THEN 'Top Customer'
        WHEN r.revenue_rank <= 50 THEN 'Moderate Customer'
        ELSE 'New Customer'
    END AS customer_category
FROM 
    ranked_customers r
WHERE 
    r.total_revenue IS NOT NULL 
    AND r.revenue_rank <= 100
ORDER BY 
    r.total_revenue DESC
LIMIT 20;

WITH item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
filtered_items AS (
    SELECT 
        it.i_item_id,
        it.i_product_name,
        is.total_quantity,
        is.total_profit
    FROM 
        item it 
    JOIN 
        item_sales is ON it.i_item_sk = is.ws_item_sk
    WHERE 
        it.i_current_price > 0 
        AND is.total_profit IS NOT NULL
)
SELECT 
    fi.i_item_id,
    fi.i_product_name,
    fi.total_quantity,
    fi.total_profit,
    CASE 
        WHEN fi.total_profit > (SELECT AVG(total_profit) FROM filtered_items) THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_category
FROM 
    filtered_items fi
ORDER BY 
    fi.total_profit DESC
FETCH FIRST 50 ROWS ONLY;

SELECT 
    DISTINCT sm.sm_carrier,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_order_value,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) >= 100 THEN 'High Volume Carrier'
        ELSE 'Low Volume Carrier'
    END AS carrier_category
FROM 
    ship_mode sm
LEFT JOIN 
    web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
WHERE 
    sm.sm_type NOT LIKE '%Ground%'
    AND ws.ws_sales_price >= (SELECT AVG(ws_ext_sales_price) FROM web_sales)
GROUP BY 
    sm.sm_carrier
HAVING 
    SUM(ws.ws_net_paid) IS NOT NULL
ORDER BY 
    total_order_value DESC
LIMIT 10;

WITH inventory_summary AS (
    SELECT 
        inv.inv_warehouse_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv.inv_item_sk) AS unique_items
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
inventory_check AS (
    SELECT 
        w.w_warehouse_id,
        CASE 
            WHEN is.total_inventory < 1000 THEN 'Stock Alert'
            ELSE 'Sufficient Stock'
        END AS stock_status
    FROM 
        warehouse w 
    JOIN 
        inventory_summary is ON w.w_warehouse_sk = is.inv_warehouse_sk
)
SELECT 
    ic.w_warehouse_id,
    ic.stock_status,
    COUNT(*) OVER() AS total_warehouses
FROM 
    inventory_check ic
WHERE 
    ic.stock_status = 'Stock Alert';
