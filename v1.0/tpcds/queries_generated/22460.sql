
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_id
), return_data AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(wr_return_number) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_return_amt > 0 
    GROUP BY 
        wr_refunded_customer_sk
), customer_segmentation AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.order_count,
    sd.avg_net_paid,
    rd.total_returns,
    rd.return_count,
    cs.c_customer_id,
    cs.gender_rank
FROM 
    sales_data sd
LEFT JOIN 
    return_data rd ON sd.web_site_id = (
        SELECT TOP 1 ws.web_site_id 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = rd.wr_refunded_customer_sk 
        ORDER BY ws.ws_sales_price DESC
    )
JOIN 
    customer_segmentation cs ON cs.gender_rank <= 3
WHERE 
    sd.total_sales IS NOT NULL 
    AND (rd.total_returns IS NULL OR rd.total_returns < 100)
ORDER BY 
    sd.total_sales DESC 
LIMIT 100;
