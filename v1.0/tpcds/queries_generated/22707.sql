
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.web_site_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS distinct_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
QuarterlySales AS (
    SELECT 
        dd.d_year,
        dd.d_quarter_seq,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_quarter_seq
),
TotalInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(COALESCE(rs.ws_sales_price, 0)) AS total_sales_price,
    SUM(COALESCE(cr.total_returned, 0)) AS total_returns,
    AVG(COALESCE(ts.total_sales, 0)) FILTER (WHERE ts.total_sales > 0) AS avg_quarterly_sales,
    MAX(CASE WHEN ti.total_quantity IS NULL THEN 'Out of Stock' ELSE 'In Stock' END) AS stock_status
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN 
    QuarterlySales ts ON EXTRACT(YEAR FROM CURRENT_DATE) = ts.d_year
LEFT JOIN 
    TotalInventory ti ON rs.ws_item_sk = ti.inv_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND (c.c_birth_day IS NULL OR c.c_birth_month IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
    AND MAX(ca.ca_zip) IS NOT NULL
ORDER BY 
    total_sales_price DESC NULLS LAST;
