
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452001 AND 2452065
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned,
        COUNT(DISTINCT cr.returning_addr_sk) AS unique_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk IS NOT NULL
    GROUP BY 
        cr.returning_customer_sk
),
AggregateStats AS (
    SELECT 
        ca.ca_country,
        COALESCE(CD.cd_gender, 'U') AS gender,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        MAX(DATE_PART('year', d.d_date::date) - c.c_birth_year) AS oldest_customer_age
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ca.ca_country, gender
),
SalesWithReturns AS (
    SELECT 
        a.ca_country,
        a.gender,
        a.total_sales,
        a.avg_profit,
        r.total_returned,
        r.unique_returns,
        RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
    FROM 
        AggregateStats a
    LEFT JOIN 
        CustomerReturns r ON r.returning_customer_sk = c.c_customer_sk
)
SELECT 
    sw.ca_country,
    sw.gender,
    sw.total_sales,
    sw.avg_profit,
    sw.total_returned,
    sw.unique_returns,
    CASE 
        WHEN sw.total_sales IS NULL THEN 'No Sales' 
        WHEN sw.total_sales < 1000 THEN 'Low Sales' 
        ELSE 'High Sales' 
    END AS sales_category
FROM 
    SalesWithReturns sw
WHERE 
    sw.sales_rank <= 10
ORDER BY 
    sw.total_sales DESC
LIMIT 50;

-- Handling NULL cases and irrelevant cases explicitly for enrolled customers
SELECT 
    DISTINCT COALESCE(c.c_first_name, 'Unknown') AS first_name, 
    COALESCE(c.c_last_name, 'Unknown') AS last_name,
    NULLIF(c.c_email_address, '') AS email_address,
    COALESCE(NULLIF(HD.hd_buy_potential, 'Unknown'), 'Not Specified') AS buy_potential 
FROM 
    customer c
LEFT JOIN 
    household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
WHERE 
    c.c_first_name IS NOT NULL
AND 
    c.c_last_name IS NOT NULL
ORDER BY 
    first_name ASC, last_name ASC;
