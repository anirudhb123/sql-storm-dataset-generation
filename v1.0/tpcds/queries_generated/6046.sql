
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        i.i_category,
        i.i_brand,
        date_dim.d_year,
        date_dim.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND date_dim.d_year = 2022 
        AND ca.ca_state IN ('CA', 'TX', 'NY')
),
aggregated_sales AS (
    SELECT 
        sd.ca_state,
        sd.i_category,
        sd.i_brand,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid
    FROM 
        sales_data sd
    GROUP BY 
        sd.ca_state, sd.i_category, sd.i_brand
),
ranked_sales AS (
    SELECT 
        as.ca_state,
        as.i_category,
        as.i_brand,
        as.total_quantity,
        as.total_net_paid,
        RANK() OVER (PARTITION BY as.ca_state ORDER BY as.total_net_paid DESC) AS rank
    FROM 
        aggregated_sales as
)
SELECT 
    rs.ca_state,
    rs.i_category,
    rs.i_brand,
    rs.total_quantity,
    rs.total_net_paid
FROM 
    ranked_sales rs
WHERE 
    rs.rank <= 5
ORDER BY 
    rs.ca_state, rs.total_net_paid DESC;
