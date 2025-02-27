
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_net_paid
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
FinalSales AS (
    SELECT 
        item.i_item_id,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_net_paid, 0) AS total_net_paid,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_net_paid, 0) DESC) AS rank
    FROM 
        item
    LEFT JOIN 
        (SELECT 
            ws_item_sk, 
            SUM(total_quantity) AS total_quantity, 
            SUM(total_net_paid) AS total_net_paid
         FROM 
            SalesData 
         GROUP BY 
            ws_item_sk) AS sd 
    ON item.i_item_sk = sd.ws_item_sk
)
SELECT 
    f.i_item_id,
    f.total_quantity,
    f.total_net_paid,
    CASE 
        WHEN f.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS sales_category
FROM 
    FinalSales f
WHERE 
    f.total_net_paid > 2000
OR 
    EXISTS (
        SELECT 1 
        FROM store_returns sr
        WHERE sr.sr_item_sk = f.i_item_id 
        AND sr.sr_return_quantity > 1
    )
ORDER BY 
    f.total_net_paid DESC;
