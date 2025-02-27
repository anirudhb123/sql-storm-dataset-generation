
WITH RECURSIVE item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales
    FROM 
        item i
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer_demographics cd
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_net_paid_inc_tax) > 1000
),
sales_summary AS (
    SELECT 
        itm.i_item_id, 
        itm.i_item_desc,
        COALESCE(sum(sts.ss_net_paid), 0) AS total_store_sales,
        COALESCE(sum(wbs.ws_net_paid), 0) AS total_web_sales
    FROM 
        item itm
    LEFT JOIN 
        store_sales sts ON itm.i_item_sk = sts.ss_item_sk
    LEFT JOIN 
        web_sales wbs ON itm.i_item_sk = wbs.ws_item_sk
    GROUP BY 
        itm.i_item_id, itm.i_item_desc
)
SELECT 
    a.i_item_id,
    a.i_item_desc,
    COALESCE(b.total_store_sales, 0) AS total_store_sales,
    COALESCE(b.total_web_sales, 0) AS total_web_sales,
    c.gender AS demographic_gender,
    c.marital_status AS demographic_marital_status,
    SUM(b.total_store_sales + b.total_web_sales) AS total_sales,
    CASE 
        WHEN COUNT(DISTINCT c.c_customer_sk) > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_top_customers
FROM 
    item_sales a
JOIN 
    sales_summary b ON a.i_item_id = b.i_item_id
LEFT JOIN 
    top_customers c ON (b.total_store_sales > 100 OR b.total_web_sales > 100)
GROUP BY 
    a.i_item_id, a.i_item_desc, c.gender, c.marital_status
ORDER BY 
    total_sales DESC
LIMIT 10;
