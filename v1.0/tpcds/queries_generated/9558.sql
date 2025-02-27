
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_income_band_sk,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        ws.ws_sales_price, ws.ws_quantity, ws.ws_net_profit, cd.cd_gender, cd.cd_income_band_sk, d.d_year
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.cd_income_band_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.d_year,
    rs.cd_gender,
    rs.cd_income_band_sk,
    SUM(rs.total_sales) AS summed_sales,
    AVG(rs.ws_net_profit) AS average_net_profit,
    SUM(rs.order_count) AS total_orders
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    rs.d_year, rs.cd_gender, rs.cd_income_band_sk
ORDER BY 
    rs.d_year, rs.cd_income_band_sk, summed_sales DESC;
