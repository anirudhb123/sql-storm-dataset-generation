
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        i.i_brand,
        CASE 
            WHEN i.i_current_price < 50 THEN 'Low'
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS price_band
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk, i.i_brand, price_band
),
TopSales AS (
    SELECT 
        d.d_year,
        sd.price_band,
        COUNT(DISTINCT sd.ws_item_sk) AS items_sold,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_sales) AS total_revenue
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk)
    GROUP BY 
        d.d_year, sd.price_band
)
SELECT 
    t.d_year,
    t.price_band,
    t.items_sold,
    t.total_quantity_sold,
    t.total_revenue,
    RANK() OVER (PARTITION BY t.d_year ORDER BY t.total_revenue DESC) AS revenue_rank
FROM 
    TopSales t
WHERE 
    t.total_revenue > 10000
ORDER BY 
    t.d_year, t.revenue_rank;
