
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
ReturnStats AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns cr ON ws.ws_order_number = cr.wr_order_number
    GROUP BY 
        ws.ws_bill_customer_sk
),
IncomeStats AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.order_count,
        cs.last_order_date,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnStats rs ON cs.c_customer_id = rs.ws_bill_customer_sk
)
SELECT 
    r.customer_count,
    s.*
FROM 
    RankedSales s
JOIN 
    IncomeStats r ON s.total_web_sales > (SELECT AVG(total_web_sales) FROM RankedSales) 
WHERE 
    s.order_count >= 3
ORDER BY 
    r.customer_count DESC, 
    s.sales_rank, 
    s.total_web_sales DESC
FETCH FIRST 100 ROWS ONLY;
