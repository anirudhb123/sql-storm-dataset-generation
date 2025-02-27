
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_id,
        c.cc_name,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        ws.web_site_id,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_id,
        c.cc_name,
        cd.cd_gender,
        cd.cd_credit_rating
),
Ranking AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.total_sales,
    r.order_count,
    r.avg_net_profit,
    r.d_year,
    r.d_month_seq,
    r.w_warehouse_id,
    r.cc_name,
    r.cd_gender,
    r.cd_credit_rating
FROM 
    Ranking r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year, r.total_sales DESC;
