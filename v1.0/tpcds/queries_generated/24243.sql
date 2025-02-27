
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt) AS net_revenue,
        COUNT(CASE WHEN ws.ws_quantity > 5 THEN 1 END) AS large_orders,
        (SELECT COUNT(DISTINCT wr_item_sk) 
         FROM web_returns
         WHERE wr_returned_date_sk = ws.ws_sold_date_sk AND wr_web_page_sk = ws.ws_web_page_sk) AS return_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY ws.web_site_id, ws.web_name
),
inventory_levels AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MAX(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS max_quantity
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= CURRENT_DATE AND i.i_rec_end_date >= CURRENT_DATE
    GROUP BY i.i_item_sk
),
return_analysis AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS return_occurrences,
        SUM(wr_return_amt) AS total_return_value,
        MAX(wr_return_ship_cost) AS max_ship_cost
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    sd.web_site_id,
    sd.web_name,
    sd.total_sales,
    sd.total_discount,
    sd.net_revenue,
    sd.large_orders,
    COALESCE(raid.return_occurrences, 0) AS total_returns,
    COALESCE(raid.total_return_value, 0) AS total_return_value,
    COALESCE(inv.total_quantity, 0) AS available_inventory,
    COALESCE(inv.max_quantity, 0) AS max_inventory,
    CASE 
        WHEN sd.net_revenue > 10000 THEN 'High Revenue'
        WHEN sd.net_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM sales_data sd
LEFT JOIN return_analysis raid ON sd.web_site_id = raid.wr_item_sk
LEFT JOIN inventory_levels inv ON raid.wr_item_sk = inv.i_item_sk
ORDER BY sd.total_sales DESC, sd.web_name ASC;
