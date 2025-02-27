
WITH RECURSIVE sales_cycle AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_quantity,
        ss_net_paid,
        1 AS cycle
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    UNION ALL
    SELECT 
        ss_store_sk, 
        ss_item_sk,
        ss_quantity + s.ss_quantity,
        ss_net_paid + s.ss_net_paid,
        cycle + 1
    FROM 
        store_sales s
    JOIN 
        sales_cycle sc ON s.ss_store_sk = sc.ss_store_sk AND s.ss_item_sk = sc.ss_item_sk
    WHERE 
        sc.cycle < 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
),
average_profit AS (
    SELECT 
        cd_gender,
        hd_buy_potential,
        AVG(total_profit) AS avg_profit
    FROM 
        customer_info
    GROUP BY 
        cd_gender, hd_buy_potential
)
SELECT 
    st.s_store_name,
    SUM(sc.ss_quantity) AS total_sales_quantity,
    SUM(sc.ss_net_paid) AS total_sales_net,
    ap.avg_profit,
    CASE 
        WHEN SUM(sc.ss_net_paid) IS NULL THEN 'No Sales'
        WHEN SUM(sc.ss_net_paid) > ap.avg_profit THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance
FROM 
    sales_cycle sc
JOIN 
    store st ON sc.ss_store_sk = st.s_store_sk
JOIN 
    average_profit ap ON st.s_store_sk = ap.cd_gender
GROUP BY 
    st.s_store_name, ap.avg_profit
ORDER BY 
    total_sales_net DESC;
