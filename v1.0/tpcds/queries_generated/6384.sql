
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        c.cd_age,
        i.i_category
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 6
        AND c.cd_gender = 'F'
),
AggregatedData AS (
    SELECT 
        d_year,
        d_month_seq,
        i_category,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, i_category
)
SELECT 
    d_year,
    d_month_seq,
    i_category,
    total_quantity,
    total_sales,
    total_profit,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
FROM 
    AggregatedData
ORDER BY 
    d_year, d_month_seq, profit_rank;
