
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.bill_customer_sk, ws.bill_cdemo_sk
),
TopCustomers AS (
    SELECT 
        r.bill_customer_sk,
        r.bill_cdemo_sk,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.ca_city,
        d.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address d ON c.c_current_addr_sk = d.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ct.c_first_name,
    ct.c_last_name,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    STRING_AGG(DISTINCT ws.ws_ship_date_sk::TEXT, ', ') AS ship_dates
FROM 
    TopCustomers tc
JOIN 
    CustomerDetails ct ON tc.bill_customer_sk = ct.c_customer_sk
JOIN 
    web_sales ws ON tc.bill_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ct.c_first_name, ct.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
