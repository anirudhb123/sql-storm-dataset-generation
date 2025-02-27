
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.sales_rank
    FROM 
        item 
    JOIN 
        SalesData sd ON item.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.sales_rank <= 5
)
SELECT 
    r.i_item_id,
    r.i_item_desc,
    COALESCE(r.total_quantity, 0) AS total_quantity,
    COALESCE(r.total_sales, 0) AS total_sales,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Performer'
        WHEN r.total_sales <= 1000 AND r.total_sales > 0 THEN 'Moderate Performer'
        ELSE 'No Sales'
    END AS performance_category
FROM 
    RankedSales r
LEFT JOIN 
    (SELECT 
        sd.ws_item_sk,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
     FROM 
        web_sales sd
     JOIN 
        customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
     GROUP BY 
        sd.ws_item_sk) uc ON r.ws_item_sk = uc.ws_item_sk
WHERE 
    uc.unique_customers IS NOT NULL
ORDER BY 
    r.total_sales DESC;
