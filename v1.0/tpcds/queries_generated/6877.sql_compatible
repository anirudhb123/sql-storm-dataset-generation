
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_sales_value,
        d.d_year AS sales_year,
        d.d_quarter_seq AS sales_quarter,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ws.web_site_sk, d.d_year, d.d_quarter_seq, cd.cd_gender, cd.cd_marital_status, ca.ca_state
),
state_summary AS (
    SELECT
        ss.sales_year,
        ss.sales_quarter,
        ss.ca_state,
        SUM(ss.total_sales_quantity) AS total_quantity_by_state,
        SUM(ss.total_sales_value) AS total_value_by_state
    FROM 
        sales_summary ss
    GROUP BY 
        ss.sales_year, ss.sales_quarter, ss.ca_state
)
SELECT 
    s.sales_year,
    s.sales_quarter,
    s.ca_state,
    s.total_quantity_by_state,
    s.total_value_by_state,
    RANK() OVER (PARTITION BY s.sales_year, s.sales_quarter ORDER BY s.total_value_by_state DESC) AS sales_rank
FROM 
    state_summary s
WHERE 
    s.total_value_by_state > 10000
ORDER BY 
    s.sales_year, s.sales_quarter, sales_rank;
