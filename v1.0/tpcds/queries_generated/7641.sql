
WITH customer_stats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status
),
item_stats AS (
    SELECT 
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        i.i_product_name
),
aggregated_stats AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        is.total_quantity_sold,
        is.average_sales_price,
        cs.total_quantity AS total_quantity_by_gender,
        cs.total_sales AS total_sales_by_gender,
        cs.unique_customers
    FROM 
        customer_stats cs
    JOIN item_stats is ON cs.total_quantity > is.total_quantity_sold
)
SELECT 
    cd_gender,
    cd_marital_status,
    SUM(total_quantity_sold) AS sold_units,
    AVG(average_sales_price) AS avg_price,
    SUM(total_quantity_by_gender) AS quantity_by_gender,
    SUM(total_sales_by_gender) AS sales_value,
    COUNT(DISTINCT unique_customers) AS distinct_customers
FROM 
    aggregated_stats
GROUP BY 
    cd_gender,
    cd_marital_status
ORDER BY 
    sales_value DESC;
