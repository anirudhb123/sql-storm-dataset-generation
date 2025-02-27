
WITH ranked_sales AS (
    SELECT
        ws.web_site_id,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
), 
total_sales AS (
    SELECT
        w.warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM
        ranked_sales rs
    JOIN
        inventory i ON rs.ws_item_sk = i.inv_item_sk
    JOIN
        warehouse w ON i.inv_warehouse_sk = w.warehouse_sk
    GROUP BY
        w.warehouse_id
), 
return_summary AS (
    SELECT 
        wr.rs_item_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.rs_item_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    MAX(t.total_sales_value) AS max_sales_by_warehouse,
    COALESCE(SUM(rs.return_count), 0) AS total_returns
FROM
    customer c
LEFT JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN
    total_sales t ON t.warehouse_id = (
        SELECT
            w.warehouse_id
        FROM
            warehouse w
        WHERE
            w.warehouse_sq_ft = (SELECT AVG(w2.warehouse_sq_ft) FROM warehouse w2)
        LIMIT 1
    )
LEFT JOIN
    return_summary rs ON cs.cs_item_sk = rs.rs_item_sk
WHERE
    c.c_birth_year IS NOT NULL
    AND ca.ca_state = 'CA'
GROUP BY
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 50;
