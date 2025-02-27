
WITH SalesData AS (
    SELECT 
        ws_sales_price,
        ws_net_profit,
        i_item_desc,
        cd_gender,
        cd_marital_status,
        d_year,
        s_store_name
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
),
AggregatedData AS (
    SELECT 
        sd.i_item_desc,
        COUNT(*) AS total_sales,
        SUM(sd.ws_sales_price) AS total_revenue,
        SUM(sd.ws_net_profit) AS total_net_profit,
        MAX(sd.ws_sales_price) AS max_sales_price,
        MIN(sd.ws_sales_price) AS min_sales_price,
        sd.s_store_name,
        sd.d_year
    FROM 
        SalesData sd
    GROUP BY 
        sd.i_item_desc, sd.s_store_name, sd.d_year
)
SELECT 
    ad.d_year,
    ad.s_store_name,
    ad.i_item_desc,
    ad.total_sales,
    ad.total_revenue,
    ad.total_net_profit,
    ad.max_sales_price,
    ad.min_sales_price
FROM 
    AggregatedData ad
ORDER BY 
    ad.d_year, ad.s_store_name, ad.total_revenue DESC
LIMIT 100;
