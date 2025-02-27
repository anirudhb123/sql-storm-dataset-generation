
WITH AddressStats AS (
    SELECT 
        ca.city AS city,
        COUNT(DISTINCT c.customer_sk) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.salutation, ' ', c.first_name, ' ', c.last_name), '; ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city
),
DateRange AS (
    SELECT 
        d.d_date AS date,
        d.d_month_seq AS month_seq
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
ItemStats AS (
    SELECT 
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ds.month_seq,
    as.city,
    as.customer_count,
    as.customer_names,
    is.item_id,
    is.total_sales,
    is.avg_price
FROM 
    DateRange ds
JOIN 
    AddressStats as ON as.city IS NOT NULL
JOIN 
    ItemStats is ON is.total_sales > 0
ORDER BY 
    ds.month_seq, as.customer_count DESC, is.total_sales DESC;
