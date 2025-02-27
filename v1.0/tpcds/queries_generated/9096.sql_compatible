
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
), 
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_sales_amount DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.d_year,
    rs.d_month_seq,
    COUNT(*) AS number_of_items,
    SUM(rs.total_sales_quantity) AS total_units_sold,
    SUM(rs.total_sales_amount) AS total_revenue,
    AVG(rs.total_discount_amount) AS average_discount,
    AVG(CASE 
        WHEN rs.sales_rank <= 10 THEN rs.total_sales_amount 
        ELSE 0 
    END) AS average_top_10_sales
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 100
GROUP BY 
    rs.d_year, rs.d_month_seq
ORDER BY 
    rs.d_year DESC, rs.d_month_seq DESC;
