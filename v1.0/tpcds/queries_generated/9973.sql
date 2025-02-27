
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.d_year,
    r.d_month_seq,
    r.total_quantity,
    r.total_sales,
    r.avg_net_profit
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.d_year, r.d_month_seq, r.sales_rank;
