
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        cds.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cds ON c.c_current_cdemo_sk = cds.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (5, 6)  -- May and June
    GROUP BY 
        ws.web_site_id, cds.cd_gender
)

SELECT 
    r.web_site_id,
    r.cd_gender,
    r.total_quantity,
    r.total_net_paid,
    (SELECT COUNT(*) FROM RankedSales rs WHERE rs.web_site_id = r.web_site_id) AS total_gender_count,
    RANK() OVER (ORDER BY r.total_net_paid DESC) AS site_rank
FROM 
    RankedSales r
WHERE 
    r.rank = 1
ORDER BY 
    r.total_net_paid DESC;
