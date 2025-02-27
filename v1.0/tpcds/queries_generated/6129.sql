
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_paid) AS average_order_value,
        COUNT(DISTINCT c.customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.date_sk
    WHERE 
        d.year = 2023 AND d.month_seq IN (1, 2, 3)  -- First quarter of 2023
    GROUP BY 
        ws.web_site_id
),
top_websites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        sales_summary
)
SELECT 
    t.web_site_id,
    t.total_net_profit,
    t.rank,
    w.web_name,
    w.web_mkt_desc,
    w.web_country,
    AVG(item.i_current_price) AS average_item_price,
    SUM(inv.inv_quantity_on_hand) AS total_inventory
FROM 
    top_websites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
LEFT JOIN 
    item ON item.item_sk IN (SELECT ws.item_sk FROM web_sales ws WHERE ws.web_site_sk = t.web_site_id)
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = item.item_sk AND inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory WHERE inv_item_sk = item.item_sk)
WHERE 
    t.rank <= 10  -- Top 10 websites by net profit
GROUP BY 
    t.web_site_id, t.total_net_profit, w.web_name, w.web_mkt_desc, w.web_country
ORDER BY 
    t.total_net_profit DESC;
