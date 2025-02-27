
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2019 AND 2023 
    GROUP BY 
        ws.web_site_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        dd.d_year
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_quantity,
        avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_quantity DESC) AS rank
    FROM SalesData
)
SELECT 
    r.web_site_id,
    r.total_quantity,
    r.avg_net_paid,
    COUNT(*) OVER (PARTITION BY r.web_site_id) AS total_years
FROM RankedSales r
WHERE r.rank <= 3
ORDER BY r.web_site_id, r.total_quantity DESC;
