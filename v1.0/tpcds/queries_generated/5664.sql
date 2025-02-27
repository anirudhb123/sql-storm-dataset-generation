
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        i.i_current_price BETWEEN 20.00 AND 50.00
    GROUP BY 
        ws.web_site_sk
),
address_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS distinct_addresses,
        SUM(ss.total_quantity) AS total_quantity_by_state,
        SUM(ss.total_sales) AS total_sales_by_state
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.web_site_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    asu.ca_state,
    asu.distinct_addresses,
    asu.total_quantity_by_state,
    ROUND(asu.total_sales_by_state, 2) AS total_sales_by_state,
    CASE 
        WHEN asu.total_sales_by_state > 10000 THEN 'High Revenue'
        WHEN asu.total_sales_by_state BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    address_summary asu
ORDER BY 
    total_sales_by_state DESC;
