
WITH SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        MAX(ws.ws_net_profit) AS max_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_bill_customer_sk
),
RankedSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_sales,
        sd.total_orders,
        sd.avg_net_paid,
        sd.max_net_profit,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.ws_bill_customer_sk,
    rs.total_sales,
    rs.total_orders,
    rs.avg_net_paid,
    rs.max_net_profit,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    RankedSales rs
WHERE 
    rs.total_sales > 1000 
    OR rs.customer_category = 'Top Performer'
ORDER BY 
    rs.total_sales DESC;

-- Additionally, let's retrieve customers with NULL email addresses 
UNION ALL

SELECT 
    c.c_customer_sk,
    0 AS total_sales,
    0 AS total_orders,
    0 AS avg_net_paid,
    0 AS max_net_profit,
    'No Email' AS customer_category
FROM 
    customer c
WHERE 
    c.c_email_address IS NULL
ORDER BY 
    total_sales DESC;
