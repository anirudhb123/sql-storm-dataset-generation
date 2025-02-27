
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_desc,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ws.web_site_id, c.c_first_name, c.c_last_name, i.i_item_desc, ws.ws_sales_price
),
RankedSales AS (
    SELECT 
        sales.web_site_id,
        sales.c_first_name,
        sales.c_last_name,
        sales.i_item_desc,
        sales.total_quantity,
        sales.total_revenue,
        RANK() OVER (PARTITION BY sales.web_site_id ORDER BY sales.total_revenue DESC) AS revenue_rank
    FROM 
        SalesData sales
)
SELECT 
    rs.web_site_id,
    rs.c_first_name,
    rs.c_last_name,
    rs.i_item_desc,
    rs.total_quantity,
    rs.total_revenue
FROM 
    RankedSales rs
WHERE 
    rs.revenue_rank <= 5
ORDER BY 
    rs.web_site_id, rs.total_revenue DESC;
