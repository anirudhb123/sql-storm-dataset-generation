
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        i.i_item_desc,
        d.d_year,
        d.d_week_seq,
        d.d_month_seq,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Unavailable'
            ELSE CAST(i.i_current_price AS VARCHAR)
        END AS current_price,
        COALESCE(NULLIF(SUM(CASE WHEN ws_ship_mode_sk IS NOT NULL THEN 1 ELSE 0 END), 0), 0) AS mode_count
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales WHERE ws_item_sk = rs.ws_item_sk)
    GROUP BY 
        rs.ws_item_sk, rs.total_sales, i.i_item_desc, d.d_year, d.d_week_seq, d.d_month_seq
    HAVING 
        sales_rank <= 10 AND (current_price IS NOT NULL OR mode_count > 0)
)
SELECT 
    fa.ca_address_id,
    fa.ca_city,
    fa.ca_state,
    fs.total_sales,
    fs.i_item_desc,
    fs.current_price,
    CONCAT('Sales for item ', fs.i_item_desc, ' in ', fa.ca_city, ', ', fa.ca_state) AS sales_description
FROM 
    customer_address fa
LEFT JOIN 
    FilteredSales fs ON fa.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = fs.ws_item_sk)
WHERE 
    NOT EXISTS (SELECT 1 FROM store s WHERE s.s_closed_date_sk IS NOT NULL AND s.s_store_sk = fs.ws_item_sk)
ORDER BY 
    fs.total_sales DESC NULLS LAST
FETCH FIRST 20 ROWS ONLY;
