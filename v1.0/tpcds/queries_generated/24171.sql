
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_bill_customer_sk IN (
            SELECT 
                c.c_customer_sk
            FROM 
                customer c 
            WHERE 
                c.c_birth_month = 5
                AND c.c_birth_year = (SELECT MAX(c_birth_year) FROM customer) 
                AND c.c_preferred_cust_flag = 'Y'
        )
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY rs.ws_item_sk ORDER BY rs.total_sales DESC) AS filtered_rank
    FROM 
        RankedSales rs 
    WHERE 
        rs.sales_rank <= 3
),
ReturnStatistics AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.ws_order_number,
    fs.total_sales,
    fs.filtered_rank,
    COALESCE(rs.total_returns, 0) AS returns_count,
    COALESCE(rs.total_return_amount, 0.00) AS returns_value,
    CASE 
        WHEN rs.total_returns IS NOT NULL AND rs.total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    STRING_AGG(DISTINCT ci.c_email_address ORDER BY ci.c_email_address) AS customer_emails
FROM 
    FilteredSales fs
LEFT JOIN 
    ReturnStatistics rs ON fs.ws_item_sk = rs.wr_item_sk
LEFT JOIN 
    customer ci ON ci.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = fs.ws_item_sk 
            AND ws_order_number = fs.ws_order_number 
            LIMIT 1
    )
GROUP BY 
    fs.ws_item_sk, fs.ws_order_number, fs.total_sales, fs.filtered_rank, rs.total_returns, rs.total_return_amount
HAVING 
    fs.total_sales > (SELECT AVG(total_sales) FROM RankedSales) OR 
    fs.filtered_rank = 1
ORDER BY 
    total_sales DESC, return_status, fs.ws_item_sk;
