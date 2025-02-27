
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        cd.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country = 'USA'
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                   AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
state_sales AS (
    SELECT 
        ca_state,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        sales_data
    WHERE 
        rn <= 5
    GROUP BY 
        ca_state
),
top_states AS (
    SELECT 
        ca_state,
        total_sales,
        order_count,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS state_rank
    FROM 
        state_sales
)
SELECT 
    ts.ca_state,
    ts.total_sales,
    ts.order_count,
    density_rank,
    CASE 
        WHEN ts.order_count > 100 THEN 'High Volume'
        WHEN ts.order_count BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    top_states ts
WHERE 
    ts.state_rank <= 10
ORDER BY 
    ts.total_sales DESC;

```
