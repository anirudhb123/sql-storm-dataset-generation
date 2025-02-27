
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE 
        ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ws.ws_bill_cdemo_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_bill_cdemo_sk
),
ReturnedData AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
SalesAnalysis AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_sales,
        rd.total_returned,
        sd.total_orders,
        COALESCE(sd.total_sales - rd.total_returned, sd.total_sales) AS net_sales,
        DATEDIFF(DAY, MIN(d.d_date), MAX(d.d_date)) AS sale_duration
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnedData rd ON sd.ws_sold_date_sk = rd.sr_returned_date_sk
    JOIN 
        date_dim d ON d.d_date_sk = sd.ws_sold_date_sk
    GROUP BY 
        sd.ws_sold_date_sk, sd.total_sales, rd.total_returned, sd.total_orders
),
CustomerSales AS (
    SELECT
        ch.c_first_name,
        ch.c_last_name,
        SUM(sa.net_sales) AS total_net_sales,
        COUNT(sa.total_orders) AS order_count
    FROM 
        CustomerHierarchy ch
    JOIN 
        SalesAnalysis sa ON ch.c_current_cdemo_sk = sa.ws_bill_cdemo_sk
    GROUP BY 
        ch.c_first_name, ch.c_last_name
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_sales,
    cs.order_count,
    ROW_NUMBER() OVER (ORDER BY cs.total_net_sales DESC) AS sales_rank
FROM 
    CustomerSales cs
WHERE 
    cs.total_net_sales > 1000
ORDER BY 
    cs.total_net_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
