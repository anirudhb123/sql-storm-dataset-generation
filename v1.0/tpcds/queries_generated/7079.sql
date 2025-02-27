
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id, 
        total_quantity, 
        total_sales 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
),
CustomerSegments AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cd.cd_gender
)
SELECT 
    tw.web_site_id,
    tw.total_quantity AS site_total_quantity,
    tw.total_sales AS site_total_sales,
    cs.cd_gender,
    cs.customer_count,
    cs.total_quantity AS segment_total_quantity,
    cs.total_sales AS segment_total_sales
FROM 
    TopWebsites tw
JOIN 
    CustomerSegments cs ON tw.total_quantity > cs.total_quantity
ORDER BY 
    tw.total_sales DESC, cs.customer_count DESC;
