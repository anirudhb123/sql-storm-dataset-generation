
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_unit_price,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
    GROUP BY 
        d.d_year
), CustomerSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), ReturnSummary AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_return_count,
        AVG(sr_return_quantity) AS average_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.average_unit_price,
    ss.total_quantity_sold,
    cs.customer_count,
    cs.avg_purchase_estimate,
    rs.total_return_amount,
    rs.total_return_count,
    rs.average_return_quantity
FROM 
    SalesSummary ss
JOIN 
    CustomerSummary cs ON 1=1
LEFT JOIN 
    ReturnSummary rs ON ss.total_orders > 0
ORDER BY 
    ss.d_year;
