
WITH CTE_Sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
    GROUP BY 
        ws.web_site_id
),
CTE_AverageReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
CTE_CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        SUM(CASE WHEN ws.ws_order_number IS NOT NULL THEN 1 ELSE 0 END) AS order_count,
        COALESCE(avg_ret.avg_return_amt, 0) AS average_return
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CTE_AverageReturns avg_ret ON c.c_customer_sk = avg_ret.refunded_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_state
),
CTE_IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.ca_state,
    cs.order_count,
    cs.average_return,
    ib.ib_income_band_sk,
    ib.customer_count
FROM 
    CTE_CustomerStats cs
LEFT JOIN 
    CTE_IncomeBands ib ON cs.average_return > 0
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = cs.c_customer_sk AND ss.ss_net_paid > 100
    )
ORDER BY 
    cs.order_count DESC, cs.average_return ASC
FETCH FIRST 100 ROWS ONLY;
