
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales AS ws
    LEFT JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        (SELECT AVG(i.i_current_price) FROM item i WHERE i.i_item_sk = inv.inv_item_sk) AS avg_price
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
),
return_data AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        sr_item_sk
    FROM 
        store_returns
    WHERE 
        sr_return_amt > 0
    GROUP BY 
        sr_item_sk
),
joined_data AS (
    SELECT 
        s.store_sk,
        i.i_item_sk,
        i.i_current_price,
        COALESCE(r.total_returns, 0) AS total_returns,
        (i.i_current_price * COALESCE(r.total_returns, 0)) AS loss_amount,
        d.d_year AS sales_year
    FROM 
        item i
    INNER JOIN 
        inventory_data inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN 
        return_data r ON r.sr_item_sk = i.i_item_sk
    INNER JOIN 
        store s ON s.s_store_sk = i.i_manager_id
    INNER JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk)
)
SELECT 
    wd.web_site_name,
    SUM(jd.loss_amount) AS total_loss,
    SUM(jd.total_returns) AS total_returns,
    AVG(wd.avg_price) AS average_item_price,
    SUM(jd.total_returns) / NULLIF(SUM(jd.loss_amount), 0) AS returns_to_loss_ratio
FROM 
    joined_data jd
JOIN 
    sales_data sd ON sd.ws_order_number = jd.store_sk
JOIN 
    (SELECT 
         SUM(i_current_price) AS avg_price
     FROM 
         item 
     GROUP BY 
         i_item_sk) AS wd ON wd.i_item_sk = jd.i_item_sk
WHERE 
    jd.total_returns > 0
GROUP BY 
    wd.web_site_name
HAVING 
    AVG(WD.avg_price) < (SELECT AVG(i_current_price) FROM item) 
    AND SUM(jd.total_returns) > 100
ORDER BY 
    total_loss DESC;
