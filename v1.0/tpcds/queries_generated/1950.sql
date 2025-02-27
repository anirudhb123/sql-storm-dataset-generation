
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
        AVG(ss.ss_net_paid_inc_tax) AS avg_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450122 AND 2450186 -- Example date range
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
TopCustomers AS (
    SELECT 
        cs.c_current_cdemo_sk,
        cs.total_sales,
        cs.sales_count,
        cs.avg_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank <= 10
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_cdemo_sk = tc.c_current_cdemo_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(is.order_count, 0) AS order_count,
    COALESCE(is.total_net_paid, 0) AS total_net_paid,
    ci.ib_lower_bound,
    ci.ib_upper_bound
FROM 
    item i
LEFT JOIN 
    ItemSales is ON i.i_item_sk = is.ws_item_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk IN (SELECT tc.c_current_cdemo_sk FROM TopCustomers tc))
LEFT JOIN 
    income_band ci ON cd.cd_purchase_estimate BETWEEN ci.ib_lower_bound AND ci.ib_upper_bound
WHERE 
    i.i_current_price > 0 AND
    (ci.ib_income_band_sk IS NULL OR cd.cd_demo_sk IS NOT NULL)
ORDER BY 
    total_net_paid DESC;
