
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk < (SELECT MIN(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
DateRange AS (
    SELECT 
        d_year,
        d_month_seq,
        d_dow,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        date_dim
    LEFT JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    GROUP BY 
        d_year, d_month_seq, d_dow
),
Addresses AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_state
),
SalesAnalysis AS (
    SELECT 
        dr.d_year,
        dr.d_month_seq,
        sa.total_quantity,
        sa.total_sales,
        ad.customer_count
    FROM 
        DateRange dr
    LEFT JOIN 
        SalesCTE sa ON dr.d_month_seq = sa.ws_sold_date_sk
    LEFT JOIN 
        Addresses ad ON ad.ca_state = 
            (SELECT ca_state FROM customer_address 
             WHERE ca_address_sk = 
                 (SELECT c_current_addr_sk FROM customer 
                  WHERE c_customer_sk = sa.ws_item_sk LIMIT 1) LIMIT 1)
)
SELECT 
    d_year,
    d_month_seq,
    SUM(total_quantity) AS total_quantity_sold,
    AVG(total_sales) AS average_sales,
    SUM(customer_count) AS total_customers
FROM 
    SalesAnalysis
GROUP BY 
    d_year, d_month_seq
HAVING 
    SUM(total_quantity) > 0
ORDER BY 
    d_year DESC, d_month_seq DESC;
