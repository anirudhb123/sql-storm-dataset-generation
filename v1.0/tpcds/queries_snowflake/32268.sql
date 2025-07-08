
WITH SalesCTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sales_quantity,
        SUM(ss_net_paid_inc_tax) AS total_net_paid
    FROM store_sales
    GROUP BY ss_item_sk
    HAVING SUM(ss_quantity) > 0

    UNION ALL

    SELECT 
        i.i_item_sk,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_net_paid
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE i.i_item_sk NOT IN (SELECT ss_item_sk FROM SalesCTE)
    GROUP BY i.i_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
DateSales AS (
    SELECT 
        d.d_year,
        SUM(ss.ss_net_paid_inc_tax) AS yearly_sales
    FROM date_dim d
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE d.d_year IS NOT NULL
    GROUP BY d.d_year
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_transactions,
    cs.total_spent,
    ds.d_year,
    COALESCE(ds.yearly_sales, 0) AS yearly_sales,
    ss.total_sales_quantity,
    ss.total_net_paid
FROM CustomerStats cs
JOIN DateSales ds ON 1=1
LEFT JOIN SalesCTE ss ON ss.ss_item_sk = (SELECT MIN(ssc.ss_item_sk) 
                                            FROM SalesCTE ssc 
                                            WHERE ssc.total_sales_quantity = (SELECT MAX(total_sales_quantity) 
                                                                               FROM SalesCTE))
ORDER BY cs.total_spent DESC, ds.d_year DESC;
