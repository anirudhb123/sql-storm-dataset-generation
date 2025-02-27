
WITH RecursiveSales AS (
    SELECT 
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND 
        (c.c_birth_year BETWEEN 1970 AND 1990 OR 
         c.c_birth_year IN (SELECT DISTINCT hd_income_band_sk FROM household_demographics WHERE hd_dep_count > 2))
),
SalesWithReturnInfo AS (
    SELECT 
        rs.c_customer_id,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COALESCE(SUM(sr.return_amt), 0) AS total_returns,
        SUM(rs.ws_quantity) AS total_quantity,
        COUNT(DISTINCT CASE WHEN sr.returning_customer_sk IS NOT NULL THEN sr.returning_customer_sk END) AS return_count
    FROM 
        RecursiveSales rs
    LEFT JOIN 
        (SELECT 
             wr.returning_customer_sk,
             wr.return_amt,
             wr_item_sk
         FROM 
             web_returns wr
         WHERE 
             wr.returned_date_sk IS NOT NULL
        ) sr ON rs.ws_order_number = sr.wr_item_sk
    GROUP BY 
        rs.c_customer_id
)
SELECT 
    s.c_customer_id,
    s.total_sales,
    s.total_returns,
    s.total_quantity,
    CASE 
        WHEN s.total_sales - s.total_returns > 0 THEN 'Profit'
        ELSE 'Loss/No Profit'
    END AS profit_status,
    (SELECT COUNT(*) 
     FROM sales_with_return_info sr 
     WHERE sr.return_count > 0 AND sr.total_sales > 500
    ) AS high_returning_customers
FROM 
    SalesWithReturnInfo s
WHERE 
    (s.total_sales - s.total_returns) / NULLIF(s.total_sales, 0) > 0.1
ORDER BY 
    CASE 
        WHEN s.total_sales > 1000 THEN 1
        ELSE 2
    END,
    s.total_sales DESC
LIMIT 10 OFFSET 5;
