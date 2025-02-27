
WITH RECURSIVE MonthlySales AS (
    SELECT 
        date_dim.d_year, 
        date_dim.d_month_seq, 
        SUM(web_sales.ws_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        date_dim.d_year, 
        date_dim.d_month_seq
    UNION ALL
    SELECT 
        ms.d_year, 
        ms.d_month_seq, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        MonthlySales ms
    JOIN 
        web_sales ws ON ms.d_year = date_dim.d_year AND ms.d_month_seq = date_dim.d_month_seq
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        ms.total_sales > 1000
)
SELECT 
    ms.d_year, 
    ms.d_month_seq,
    ms.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ms.d_year ORDER BY ms.total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM MonthlySales) AS average_sales,
    COUNT(DISTINCT web_sales.ws_order_number) AS unique_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    MonthlySales ms
LEFT JOIN 
    web_sales ON ms.d_year = date_dim.d_year AND ms.d_month_seq = date_dim.d_month_seq
JOIN 
    customer_address ON web_sales.ws_bill_addr_sk = customer_address.ca_address_sk
LEFT JOIN 
    customer_demographics ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
WHERE 
    customer_demographics.cd_marital_status = 'M' 
    AND (customer_demographics.cd_gender = 'F' OR customer_demographics.cd_purchase_estimate > 500)
GROUP BY 
    ms.d_year, 
    ms.d_month_seq, 
    ms.total_sales
HAVING 
    total_sales > (SELECT AVG(total_sales) FROM MonthlySales) 
ORDER BY 
    ms.d_year, 
    ms.d_month_seq;
