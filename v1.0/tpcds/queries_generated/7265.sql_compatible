
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        c.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, c.cd_gender, c.cd_marital_status
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.d_year,
    rs.d_month_seq,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.total_quantity,
    rs.total_sales,
    rs.average_profit,
    rs.customer_count
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.d_year, rs.d_month_seq, rs.sales_rank;
