
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_discount_amt,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        s.s_store_name,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        d.d_year >= 2020
    AND 
        ws.ws_sales_price > 100
    AND 
        (ws.ws_discount_amt IS NULL OR ws.ws_discount_amt < 20)
),
TopProfitableSales AS (
    SELECT 
        d_year,
        s_store_name,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        SalesData
    WHERE 
        profit_rank <= 10
    GROUP BY 
        d_year, s_store_name
)
SELECT 
    d_year,
    s_store_name,
    total_sales,
    avg_net_profit,
    CASE 
        WHEN total_sales > (SELECT AVG(total_sales) FROM TopProfitableSales) THEN 'Above Average'
        WHEN total_sales < (SELECT AVG(total_sales) FROM TopProfitableSales) THEN 'Below Average'
        ELSE 'Average'
    END AS sales_performance_category
FROM 
    TopProfitableSales
ORDER BY 
    d_year DESC, total_sales DESC
LIMIT 50;
