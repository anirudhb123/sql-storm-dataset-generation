
WITH RankedSales AS (
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_order_number
),
TopItems AS (
    SELECT 
        rs.cs_item_sk, 
        rs.total_quantity, 
        rs.total_sales,
        i.i_item_desc,
        i.i_brand,
        c.c_customer_id,
        ROW_NUMBER() OVER (PARTITION BY rs.cs_item_sk ORDER BY rs.total_sales DESC) AS item_sales_rank
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    LEFT JOIN 
        web_sales ws ON rs.cs_item_sk = ws.ws_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category_id = i.i_category_id)
        AND c.c_customer_sk IS NOT NULL
),
PhenomenalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS return_value,
        SUM(sr_return_ship_cost) AS total_ship_cost
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ReturnRatio AS (
    SELECT 
        ti.cs_item_sk,
        ti.total_sales, 
        COALESCE(pr.total_returns, 0) AS total_returns,
        CASE 
            WHEN ti.total_sales > 0 THEN 1.0 * COALESCE(pr.total_returns, 0) / ti.total_sales
            ELSE NULL
        END AS return_ratio
    FROM 
        TopItems ti
    LEFT JOIN 
        PhenomenalReturns pr ON ti.cs_item_sk = pr.sr_item_sk
)
SELECT 
    r.cs_item_sk,
    i.i_item_desc,
    i.i_brand,
    r.return_ratio,
    CASE 
        WHEN r.return_ratio IS NULL THEN 'No Sales'
        WHEN r.return_ratio > 0.2 THEN 'High Return'
        WHEN r.return_ratio BETWEEN 0.1 AND 0.2 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    ReturnRatio r
JOIN 
    item i ON r.cs_item_sk = i.i_item_sk
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT MIN(ws_warehouse_sk) FROM web_sales WHERE ws_item_sk = r.cs_item_sk)
WHERE 
    i.i_current_price BETWEEN (SELECT MIN(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) 
    AND (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand)
ORDER BY 
    return_ratio DESC NULLS LAST;
