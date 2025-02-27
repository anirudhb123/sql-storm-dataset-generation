
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

BestSellingItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
),

SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        bs.total_sales,
        bi.i_item_id
    FROM 
        CustomerSales cs
    JOIN 
        BestSellingItems bs ON cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
    JOIN 
        item bi ON bi.i_item_id IN (SELECT i.i_item_id FROM BestSellingItems)
)

SELECT 
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    bi.i_item_id
FROM 
    SalesSummary ss
JOIN 
    item bi ON ss.i_item_id = bi.i_item_id
ORDER BY 
    ss.total_sales DESC;
