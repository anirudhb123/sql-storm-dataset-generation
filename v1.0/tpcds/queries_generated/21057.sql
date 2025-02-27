
WITH RecursiveSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_order_number, 
        ws_item_sk, 
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_order_number) AS rn,
        ws.ext_discount_amt,
        CASE 
            WHEN ws_sales_price IS NULL THEN 0
            ELSE ws_sales_price * ws_quantity
        END AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
ItemStatistics AS (
    SELECT 
        item.i_item_sk,
        COUNT(DISTINCT sales.ws_order_number) AS total_orders,
        SUM(sales.total_sales) AS total_revenue,
        AVG(sales.ws_sales_price) AS avg_price
    FROM 
        RecursiveSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_sk
),
TopItems AS (
    SELECT
        ists.i_item_sk,
        ists.total_orders,
        ists.total_revenue,
        ists.avg_price,
        DENSE_RANK() OVER (ORDER BY ists.total_revenue DESC) AS revenue_rank
    FROM 
        ItemStatistics ists
),
Customers AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'N/A') AS customer_gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        ci.c_first_name,
        ci.c_last_name
    FROM 
        customer ci 
    LEFT JOIN 
        customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.customer_gender, 
    c.marital_status, 
    COUNT(DISTINCT sales.ws_order_number) AS number_of_orders,
    SUM(sales.total_sales) AS total_spent,
    SUM(CASE WHEN c.marital_status = 'M' THEN sales.total_sales ELSE 0 END) AS married_spent,
    AVG(CASE WHEN sales.ws_item_sk IN (SELECT i_item_sk FROM TopItems WHERE revenue_rank <= 10) 
             THEN sales.ws_sales_price ELSE NULL END) AS avg_price_top_items
FROM 
    RecursiveSales sales
JOIN 
    Customers c ON sales.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    (sales.ws_sales_price IS NOT NULL OR sales.ext_discount_amt > 0)
GROUP BY 
    c.customer_gender, 
    c.marital_status
HAVING 
    total_spent > 1000 OR COUNT(DISTINCT sales.ws_order_number) > 5
ORDER BY 
    total_spent DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
