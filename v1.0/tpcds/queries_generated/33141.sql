
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
date_filtered AS (
    SELECT
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM
        date_dim d
    WHERE
        d.d_date >= '2023-01-01'
        AND d.d_date <= '2023-12-31'
),
promo_sales AS (
    SELECT
        ws.ws_web_page_sk,
        sd.total_quantity,
        sd.total_net_sales
    FROM
        web_sales ws
    JOIN
        sales_data sd ON ws.ws_item_sk = sd.ws_item_sk
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        p.p_discount_active = 'Y'
    UNION ALL
    SELECT
        ws.ws_web_page_sk,
        sd.total_quantity,
        sd.total_net_sales
    FROM
        catalog_sales cs
    JOIN
        sales_data sd ON cs.cs_item_sk = sd.ws_item_sk
    JOIN
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        p.p_discount_active = 'Y'
),
filtered_warehouses AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory
    FROM
        warehouse w
    LEFT JOIN
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY
        w.w_warehouse_sk, w.w_warehouse_name
),
final_report AS (
    SELECT
        pdf.ws_web_page_sk,
        SUM(pdf.total_quantity) AS total_quantity,
        SUM(pdf.total_net_sales) AS total_net_sales,
        fw.w_warehouse_name,
        dw.d_month_seq,
        dw.d_year
    FROM
        promo_sales pdf
    JOIN
        filtered_warehouses fw ON pdf.ws_web_page_sk = fw.w_warehouse_sk
    JOIN
        date_filtered dw ON dw.d_year = YEAR(CURRENT_DATE)
    GROUP BY
        pdf.ws_web_page_sk, fw.w_warehouse_name, dw.d_month_seq, dw.d_year
)
SELECT
    fr.ws_web_page_sk,
    fr.total_quantity,
    fr.total_net_sales,
    fr.w_warehouse_name,
    fr.d_month_seq,
    fr.d_year
FROM
    final_report fr
WHERE
    fr.total_net_sales IS NOT NULL
    AND fr.total_quantity > (SELECT AVG(total_quantity) FROM final_report)
ORDER BY
    fr.total_net_sales DESC;
