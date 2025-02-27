
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
SalesWithDetails AS (
    SELECT 
        ti.ws_sold_date_sk,
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM 
        TopItems ti
    JOIN 
        item i ON ti.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ti.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT ws_item_sk) AS num_top_items,
    SUM(total_sales) AS total_sales_amount,
    AVG(total_quantity) AS avg_quantity_sold,
    AVG(i_current_price) AS avg_item_price,
    i_brand,
    i_category
FROM 
    SalesWithDetails
GROUP BY 
    d.d_year, d.d_month_seq, i_brand, i_category
ORDER BY 
    d.d_year, d.d_month_seq, total_sales_amount DESC
LIMIT 100;
