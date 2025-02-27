
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_coupon_amt) AS total_coupons,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_sk
),
RankedSales AS (
    SELECT 
        web_site_sk,
        total_sales,
        num_orders,
        total_coupons,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    w.web_site_name,
    r.total_sales,
    r.num_orders,
    r.total_coupons,
    r.total_profit,
    r.sales_rank
FROM 
    RankedSales r
JOIN 
    web_site w ON r.web_site_sk = w.web_site_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
