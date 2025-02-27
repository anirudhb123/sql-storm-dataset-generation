
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year AS year,
        c.cd_gender AS gender,
        c.cd_marital_status AS marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2021
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.cd_gender, c.cd_marital_status
),
AggregatedData AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(sd.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales,
        COALESCE(SUM(sd.total_profit), 0) AS total_profit
    FROM 
        item
    LEFT JOIN 
        SalesData sd ON item.i_item_sk = sd.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    ad.i_item_id,
    ad.i_item_desc,
    ad.total_quantity,
    ad.total_sales,
    ad.total_profit,
    CASE 
        WHEN ad.total_sales > 100000 THEN 'High Sales'
        WHEN ad.total_sales BETWEEN 50000 AND 100000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    AggregatedData ad
ORDER BY 
    ad.total_profit DESC, ad.total_sales DESC;
