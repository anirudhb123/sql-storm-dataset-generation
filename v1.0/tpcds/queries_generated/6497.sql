
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        dd.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND p.p_discount_active = 'Y'
    GROUP BY 
        ws.web_site_id
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_sales_quantity,
        total_sales_amount,
        total_orders,
        avg_sales_price,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id,
    total_sales_quantity,
    total_sales_amount,
    total_orders,
    avg_sales_price,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;
