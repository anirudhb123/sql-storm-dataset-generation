
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid_inc_ship_tax) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        (ws.ws_net_paid_inc_ship_tax IS NOT NULL OR ws.ws_net_paid_inc_ship_tax <> 0)
    GROUP BY 
        ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders
    FROM 
        SalesData
    WHERE 
        rank_sales <= 10
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(*) AS total_returns
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_amt_inc_tax > 0
    GROUP BY 
        wr.returning_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    t.web_site_id,
    t.total_sales,
    t.total_orders,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.total_returned_amt,
    COALESCE(cr.total_returns, 0) AS total_returns,
    CASE 
        WHEN cr.total_returned_amt IS NULL THEN 'No Returns'
        WHEN cr.total_returned_amt > 1000 THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_status,
    CASE 
        WHEN c.cd_gender = 'M' AND c.cd_marital_status = 'M' THEN 'Married Male'
        WHEN c.cd_gender = 'F' AND c.cd_marital_status = 'M' THEN 'Married Female'
        ELSE 'Others'
    END AS customer_category
FROM 
    TopSites t
LEFT JOIN 
    CustomerDetails c ON c.c_customer_id IN (
        SELECT 
            wr_refunded_customer_sk 
        FROM 
            web_returns 
        WHERE 
            wr_web_page_sk IN (SELECT wp_web_page_sk FROM web_page WHERE wp_url LIKE '%special%')
    )
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_id = cr.returning_customer_sk
WHERE 
    t.total_sales > (SELECT AVG(total_sales) FROM SalesData)
ORDER BY 
    t.total_sales DESC,
    c.c_last_name DESC;

WITH RECURSIVE DateRange AS (
    SELECT 
        d_date AS start_date 
    FROM 
        date_dim 
    WHERE 
        d_year = 2023 AND d_month_seq = 1 
    UNION ALL
    SELECT 
        start_date + INTERVAL '1 DAY' 
    FROM 
        DateRange
    WHERE 
        start_date + INTERVAL '1 DAY' <= (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2023)
)
SELECT 
    dr.start_date,
    COUNT(distinct ws.ws_order_number) AS orders_count,
    SUM(ws.ws_net_paid_inc_ship_tax) AS revenue
FROM 
    DateRange dr
LEFT JOIN 
    web_sales ws ON dr.start_date = (SELECT d_date FROM date_dim WHERE d_date_sk = ws.ws_sold_date_sk)
GROUP BY 
    dr.start_date
ORDER BY 
    dr.start_date;

```
