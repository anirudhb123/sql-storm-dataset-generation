
WITH SalesData AS (
    SELECT 
        coalesce(ws.web_site_sk, cs.call_center_sk) AS source_sk,
        COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk) AS sold_date_sk,
        SUM(COALESCE(ws.ws_sales_price, cs.cs_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number)) AS order_count
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_sales_price = cs.cs_sales_price
    GROUP BY 
        ROLLUP(coalesce(ws.web_site_sk, cs.call_center_sk), COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk))
),
RankedSales AS (
    SELECT 
        source_sk,
        sold_date_sk,
        total_sales,
        order_count,
        RANK() OVER (PARTITION BY source_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
),
HighSales AS (
    SELECT 
        rs.source_sk,
        rs.sold_date_sk,
        rs.total_sales,
        rs.order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hs.total_sales, 0) AS total_sales,
    COALESCE(hs.order_count, 0) AS total_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(hs.total_sales, 0) > 0 THEN 
            (COALESCE(cr.total_return_amount, 0) / NULLIF(hs.total_sales, 0)) * 100 
        ELSE 
            0 
    END AS return_percentage
FROM 
    customer c
LEFT JOIN 
    HighSales hs ON c.c_customer_sk = hs.source_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    return_percentage DESC;
