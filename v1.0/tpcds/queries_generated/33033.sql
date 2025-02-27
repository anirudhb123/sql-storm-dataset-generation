
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_sales_price) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_customer_sk
    UNION ALL
    SELECT 
        ss_customer_sk,
        SUM(ss_sales_price)
    FROM 
        store_sales
    WHERE 
        ss_customer_sk IN (SELECT ss_customer_sk FROM SalesCTE)
    AND 
        ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales) - 7
    GROUP BY 
        ss_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        ci.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ci.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        (SELECT 
            ss_customer_sk, SUM(ss_sales_price) AS total_sales 
         FROM 
            store_sales 
         GROUP BY 
            ss_customer_sk) ci ON ci.ss_customer_sk = c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.customer_id, 
        c.cd_gender, 
        c.total_sales 
    FROM 
        CustomerInfo c 
    WHERE 
        c.sales_rank <= 10
)
SELECT 
    cc.cc_name,
    w.w_warehouse_name,
    SUM(ws.ws_sales_price) AS total_web_sales,
    COALESCE(SUM(rs.revenue), 0) AS total_return_revenue
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.customer_id
LEFT JOIN 
    (SELECT 
         wr_returning_customer_sk,
         SUM(wr_return_amt_inc_tax) AS revenue
     FROM 
         web_returns
     GROUP BY 
         wr_returning_customer_sk) rs ON rs.wr_returning_customer_sk = tc.customer_id
JOIN 
    store s ON s.s_store_sk = ws.ws_ship_address
JOIN 
    call_center cc ON cc.cc_call_center_sk = s.s_store_sk
JOIN 
    warehouse w ON w.w_warehouse_sk = s.s_warehouse_sk
GROUP BY 
    cc.cc_name,
    w.w_warehouse_name
ORDER BY 
    total_web_sales DESC
FETCH FIRST 10 ROWS ONLY;
