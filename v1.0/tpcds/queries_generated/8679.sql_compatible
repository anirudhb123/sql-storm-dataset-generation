
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
return_data AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE 
        wr.wr_returned_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023
        )
    GROUP BY 
        wr.wr_web_page_sk
)
SELECT 
    s.web_site_id,
    s.total_quantity,
    s.total_sales,
    s.total_orders,
    r.total_returns,
    r.total_returned_amount,
    (s.total_sales - COALESCE(r.total_returned_amount, 0)) AS net_sales
FROM 
    sales_data s
LEFT JOIN 
    return_data r ON s.web_site_id = r.wr_web_page_sk
ORDER BY 
    net_sales DESC
LIMIT 10;
