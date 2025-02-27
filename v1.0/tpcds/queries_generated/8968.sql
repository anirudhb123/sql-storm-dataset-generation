
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        SUM(ws.ws_discount_amt) AS total_discount,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        c.cd_gender,
        c.cd_marital_status,
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
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws.ws_item_sk, sales_year, sales_month, c.cd_gender, c.cd_marital_status, ca.ca_state
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SalesData
)
SELECT 
    rs.sales_year,
    rs.sales_month,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.ca_state,
    COUNT(*) AS customer_count,
    SUM(rs.total_quantity) AS total_quantity_sold,
    SUM(rs.total_revenue) AS total_revenue,
    AVG(rs.total_discount) AS avg_discount_per_transaction
FROM 
    RankedSales rs
WHERE 
    rs.revenue_rank <= 10
GROUP BY 
    rs.sales_year, rs.sales_month, rs.cd_gender, rs.cd_marital_status, rs.ca_state
ORDER BY 
    rs.sales_year, rs.sales_month, total_revenue DESC;
