
WITH SalesData AS (
    SELECT 
        w.warehouse_id,
        i.i_item_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        d.d_year,
        d.d_month_seq
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY w.warehouse_id, i.i_item_id, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        warehouse_id,
        i_item_id,
        total_sales,
        total_transactions,
        avg_net_profit,
        RANK() OVER (PARTITION BY warehouse_id ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    R.warehouse_id,
    R.i_item_id,
    R.total_sales,
    R.total_transactions,
    R.avg_net_profit
FROM RankedSales R
WHERE R.sales_rank <= 5
ORDER BY R.warehouse_id, R.total_sales DESC;
