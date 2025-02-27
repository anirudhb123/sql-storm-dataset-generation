
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_date_sk = ws.ws_sold_date_sk)      
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
ReturnStats AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales_from_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_bill_customer_sk = sr.sr_customer_sk
    GROUP BY 
        ws.ws_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.order_count,
    cs.total_spent,
    cs.avg_order_value,
    rs.total_returns,
    rs.total_sales_from_returns,
    COUNT(DISTINCT r.reason_sk) AS distinct_return_reasons
FROM 
    CustomerStats cs
LEFT JOIN 
    ReturnStats rs ON cs.c_current_cdemo_sk = rs.ws_customer_sk
LEFT JOIN 
    store_returns r ON cs.order_count = r.sr_return_quantity 
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
    AND (rs.total_returns IS NULL OR rs.total_returns < 5)
GROUP BY 
    cs.c_customer_id, cs.order_count, cs.total_spent, cs.avg_order_value, rs.total_returns, rs.total_sales_from_returns
HAVING 
    SUM(cs.order_count) > 1
ORDER BY 
    cs.total_spent DESC;
