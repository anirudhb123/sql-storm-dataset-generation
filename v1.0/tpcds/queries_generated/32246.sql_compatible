
WITH RECURSIVE sales_per_item AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        spi.ws_item_sk,
        spi.total_sales,
        COALESCE(si.i_item_desc, 'Unknown') AS item_description,
        ROW_NUMBER() OVER (ORDER BY spi.total_sales DESC) AS item_rank
    FROM
        sales_per_item spi
    LEFT JOIN
        item si ON spi.ws_item_sk = si.i_item_sk
),
sales_info AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_sales,
        ti.item_description,
        dd.d_year,
        dd.d_month_seq,
        dd.d_week_seq,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_ext_tax) AS total_tax
    FROM 
        top_items ti
    LEFT JOIN 
        store_sales ss ON ti.ws_item_sk = ss.ss_item_sk
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        ti.item_rank <= 10
    GROUP BY 
        ti.ws_item_sk, ti.total_sales, ti.item_description, dd.d_year, dd.d_month_seq, dd.d_week_seq
)
SELECT 
    si.ws_item_sk,
    si.total_sales,
    si.item_description,
    CONCAT('Total Items Sold: ', si.sales_count) AS item_sold_info,
    NULLIF(si.total_tax, 0) AS total_tax_collected,
    CASE 
        WHEN si.total_discount > 0 THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS discount_status
FROM 
    sales_info si
WHERE 
    si.total_sales > 5000
ORDER BY 
    si.total_sales DESC;
