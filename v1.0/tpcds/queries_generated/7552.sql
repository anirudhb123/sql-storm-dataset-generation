
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(DATEDIFF(d, dd.d_date, GETDATE())) AS avg_days_since_last_order
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.web_site_id
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
ReturnsData AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders,
    cd.total_customers,
    cd.total_estimated_spending,
    rd.total_returns,
    rd.total_returned_amount,
    sd.avg_days_since_last_order
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON 1=1
LEFT JOIN 
    ReturnsData rd ON 1=1
WHERE 
    sd.total_sales > 10000
ORDER BY 
    sd.total_sales DESC;
