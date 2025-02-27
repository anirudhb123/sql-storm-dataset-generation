
WITH customer_summary AS (
    SELECT 
        ca.city,
        cd.gender,
        cd.marital_status,
        COUNT(DISTINCT c.customer_sk) AS total_customers,
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.customer_sk = ws.bill_customer_sk
    WHERE 
        ca.state = 'CA' 
        AND cd.education_status IN ('PhD', 'Masters')
    GROUP BY 
        ca.city, cd.gender, cd.marital_status
), 
time_frame AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        d.d_year, d.d_month_seq
), 
inventory_summary AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    cs.city,
    cs.gender,
    cs.marital_status,
    tf.d_year,
    tf.d_month_seq,
    tf.total_sales,
    is.total_inventory,
    cs.total_customers,
    cs.total_net_profit
FROM 
    customer_summary cs
JOIN 
    time_frame tf ON tf.total_sales > 0
JOIN 
    inventory_summary is ON cs.city IS NOT NULL
ORDER BY 
    cs.city, tf.d_year, tf.d_month_seq;
