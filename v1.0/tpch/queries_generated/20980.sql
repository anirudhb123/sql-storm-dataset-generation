WITH RECURSIVE price_variation AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank
    FROM partsupp
    WHERE ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
supplier_region AS (
    SELECT 
        s.s_suppkey,
        n.n_nationkey,
        r.r_regionkey,
        r.r_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_comment IS NOT NULL
),
aggregated_data AS (
    SELECT 
        ps.ps_partkey,
        SUM(cs.total_order_value) AS total_sales,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps_availqty) AS max_qty
    FROM price_variation ps
    LEFT JOIN customer_orders cs ON cs.total_orders >= ps.rank 
    JOIN supplier_region sr ON sr.s_suppkey = ps.ps_suppkey
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ad.total_sales, 0) AS total_sales,
    ad.avg_supply_cost,
    ad.max_qty,
    CASE 
        WHEN ad.total_sales IS NULL AND ad.avg_supply_cost IS NULL THEN 'No Sales'
        WHEN ad.total_sales > ad.avg_supply_cost * 1.5 THEN 'High Sales'
        WHEN ad.total_sales <= ad.avg_supply_cost THEN 'Normal Sales'
        ELSE 'Other'
    END AS sales_category,
    ROW_NUMBER() OVER (ORDER BY ad.total_sales DESC, p.p_partkey) AS sales_rank
FROM part p
LEFT JOIN aggregated_data ad ON p.p_partkey = ad.ps_partkey
WHERE (p.p_retailprice IS NOT NULL OR p.p_size BETWEEN 10 AND 20)
  AND (p.p_comment IS NULL OR LENGTH(p.p_comment) > 10)
ORDER BY sales_rank, p.p_partkey
LIMIT 50 OFFSET 10;
