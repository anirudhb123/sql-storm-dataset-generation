
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        i.i_brand,
        i.i_category,
        i.i_class,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_price,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2015 AND 2020
    GROUP BY 
        cs.cs_item_sk, d.d_year, d.d_month_seq, d.d_quarter_seq, i.i_brand, i.i_category, i.i_class
),
AggregateData AS (
    SELECT 
        d_year,
        d_month_seq,
        d_quarter_seq,
        i_brand,
        i_category,
        i_class,
        SUM(total_quantity) AS year_total_quantity,
        SUM(total_sales) AS year_total_sales,
        AVG(avg_price) AS year_avg_price,
        AVG(avg_net_profit) AS year_avg_net_profit
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_quarter_seq, i_brand, i_category, i_class
)
SELECT 
    ad.d_year,
    ad.d_month_seq,
    ad.d_quarter_seq,
    ad.i_brand,
    ad.i_category,
    ad.i_class,
    ad.year_total_quantity,
    ad.year_total_sales,
    ad.year_avg_price,
    ad.year_avg_net_profit
FROM 
    AggregateData ad
WHERE 
    ad.year_total_sales > 1000000
ORDER BY 
    ad.d_year, ad.d_quarter_seq, ad.i_brand, ad.i_category, ad.i_class;
