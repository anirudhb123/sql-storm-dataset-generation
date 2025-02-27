
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year AS sales_year,
        cd.cd_gender,
        cs.cs_item_sk,
        i.i_category AS item_category,
        c.c_country AS customer_country,
        r.r_reason_desc AS return_reason
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, cd.cd_gender, cs.cs_item_sk, i.i_category, c.c_country, r.r_reason_desc
)
SELECT 
    sales_year,
    cd_gender,
    item_category,
    customer_country,
    SUM(total_quantity) AS total_units_sold,
    SUM(total_sales) AS total_revenue,
    AVG(avg_price) AS average_item_price,
    SUM(total_orders) AS unique_transactions
FROM 
    SalesData
GROUP BY 
    sales_year, cd_gender, item_category, customer_country
ORDER BY 
    sales_year, total_revenue DESC, total_units_sold DESC;
