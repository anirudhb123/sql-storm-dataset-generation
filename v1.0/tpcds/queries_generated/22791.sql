
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_return_amt > 0
    GROUP BY 
        wr_item_sk
),
FinalSales AS (
    SELECT 
        s.ss_item_sk,
        COALESCE(SUM(s.ss_sales_price), 0) AS total_sales,
        COALESCE(r.total_return_quantity, 0) AS total_returns,
        MAX(d.d_date) AS latest_sale_date,
        CASE 
            WHEN COALESCE(SUM(s.ss_sales_price), 0) = 0 THEN 'No Sales'
            WHEN COALESCE(SUM(s.ss_sales_price), 0) > COALESCE(r.total_return_quantity, 0) THEN 'Positive'
            ELSE 'Negative'
        END AS sales_status
    FROM 
        store_sales s
    LEFT JOIN 
        CustomerReturns r ON s.ss_item_sk = r.wr_item_sk
    LEFT JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    f.ss_item_sk,
    f.total_sales,
    f.total_returns,
    f.latest_sale_date,
    f.sales_status,
    CASE 
        WHEN f.total_sales > 1000 THEN 'High Performer'
        WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    FinalSales f
WHERE 
    f.latest_sale_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    f.total_sales DESC
FETCH FIRST 10 ROWS ONLY;

-- Union with outer join and NULL logic to illustrate a corner case
SELECT 
    ca.ca_address_id AS address_id,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(COALESCE(s.ss_net_profit, 0)) AS total_profit
FROM 
    customer_address ca 
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
WHERE 
    ca.ca_country IS NOT NULL AND 
    (c.c_birth_country IS NULL OR c.c_birth_country <> ca.ca_country)
GROUP BY 
    ca.ca_address_id
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY 
    total_profit DESC;
