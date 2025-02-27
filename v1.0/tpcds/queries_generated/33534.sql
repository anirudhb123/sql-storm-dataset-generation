
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        ws_item_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450300
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ranked_sales AS (
    SELECT 
        item.i_item_id,
        sd.ws_sold_date_sk,
        sd.total_sales,
        RANK() OVER (PARTITION BY item.i_item_id ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
),
product_levels AS (
    SELECT 
        rank_sales.i_item_id,
        rank_sales.ws_sold_date_sk,
        rank_sales.total_sales,
        COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
        COALESCE(NULLIF(hd.hd_buy_potential, ''), 'Unknown') AS buy_potential,
        SUM(CASE WHEN sr.returned_date_sk IS NOT NULL THEN sr.return_quantity ELSE 0 END) AS total_returns
    FROM 
        ranked_sales rank_sales
    LEFT JOIN 
        customer c ON c.c_customer_sk IN (
            SELECT DISTINCT sd.ws_bill_customer_sk FROM web_sales sd 
            WHERE sd.ws_item_sk = rank_sales.ws_item_sk
        )
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_returns sr ON sr.sr_item_sk = rank_sales.ws_item_sk 
                         AND sr.sr_returned_date_sk BETWEEN rank_sales.ws_sold_date_sk AND rank_sales.ws_sold_date_sk + 30
    GROUP BY 
        rank_sales.i_item_id,
        rank_sales.ws_sold_date_sk,
        cd.cd_gender,
        hd.hd_buy_potential
)
SELECT 
    p.i_item_id,
    SUM(p.total_sales) AS total_sales,
    COUNT(DISTINCT p.customer_gender) AS distinct_genders,
    AVG(p.total_returns) AS avg_returns,
    COUNT(DISTINCT p.buy_potential) AS unique_buy_potential_count
FROM 
    product_levels p
GROUP BY 
    p.i_item_id
HAVING 
    SUM(p.total_sales) > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
