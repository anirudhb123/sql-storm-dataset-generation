
WITH RECURSIVE Sales_CTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY
        ws_item_sk
),
Top_Sales AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_paid,
        ROW_NUMBER() OVER (ORDER BY sales.total_net_paid DESC) AS rank
    FROM
        Sales_CTE sales
    JOIN
        item ON sales.ws_item_sk = item.i_item_sk
),
Customer_Spend AS (
    SELECT
        c.c_customer_id,
        SUM(ws.net_paid_inc_tax) AS total_spending,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
Customer_Demographics AS (
    SELECT
        cd.cd_demo_sk,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_dep_count) AS total_dependents
    FROM
        customer_demographics cd
    WHERE
        cd_cd_demo_sk IS NOT NULL
    GROUP BY
        cd.cd_demo_sk
)
SELECT
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_net_paid,
    cs.c_customer_id,
    cs.total_spending,
    cd.avg_purchase_estimate,
    cd.total_dependents
FROM
    Top_Sales ts
FULL OUTER JOIN
    Customer_Spend cs ON ts.i_item_id LIKE CONCAT('%', cs.c_customer_id, '%')
FULL OUTER JOIN
    Customer_Demographics cd ON cs.total_orders < cd.avg_purchase_estimate
WHERE
    ts.rank <= 10
AND 
    (ts.total_net_paid IS NOT NULL OR cd.avg_purchase_estimate IS NULL)
ORDER BY 
    ts.total_net_paid DESC, cs.total_orders ASC;
