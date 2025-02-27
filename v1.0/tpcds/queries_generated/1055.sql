
WITH recent_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
yearly_totals AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        d.d_year
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_profit DESC
    LIMIT 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ri.r_reason_desc,
    COALESCE(rs.total_sales, 0) AS sales_last_30_days,
    ti.total_quantity_sold,
    ti.total_profit,
    yt.total_sales AS yearly_sales
FROM 
    customer_info ci
LEFT JOIN 
    recent_sales rs ON ci.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    reason ri ON ri.r_reason_sk = (SELECT MIN(sr_reason_sk) FROM store_returns sr WHERE sr.returned_date_sk = rs.ws_sold_date_sk)
JOIN 
    top_items ti ON ti.i_item_id IN (SELECT i.i_item_id FROM item i WHERE i.i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = ci.c_customer_sk))
JOIN 
    yearly_totals yt ON yt.d_year = (SELECT MAX(d_year) FROM date_dim)
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    ci.c_last_name ASC, ci.c_first_name ASC;
