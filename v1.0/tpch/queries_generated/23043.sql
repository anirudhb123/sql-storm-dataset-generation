WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    WHERE EXISTS (
        SELECT 1 FROM part p WHERE p.p_partkey = ps.ps_partkey AND p.p_retailprice < 500
    )
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
)
SELECT COALESCE(o.order_details, 'N/A') AS order_details,
       COALESCE(r.supp_details, 'No Supplier Info') AS supplier_info,
       p.part_details, 
       CASE 
           WHEN p.total_avail_qty IS NULL THEN 'Not Available'
           ELSE CAST(p.total_avail_qty AS VARCHAR)
       END AS availability_report
FROM (
    SELECT o.o_orderkey, o.item_count, o.total_price,
           'Order ' || o.o_orderkey || ' has ' || o.item_count || ' items costing ' || o.total_price AS order_details
    FROM OrderSummary o
) o
FULL OUTER JOIN (
    SELECT ps.ps_partkey, stats.total_avail_qty, stats.avg_supply_cost,
           'Part ' || p.p_partkey || ' available in quantity ' || stats.total_avail_qty || ' with an avg cost of ' || stats.avg_supply_cost AS part_details
    FROM PartSupplierStats stats
    JOIN part p ON stats.ps_partkey = p.p_partkey
) p ON o.o_orderkey = p.ps_partkey
LEFT JOIN RankedSuppliers r ON r.rn = 1 AND r.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.ps_partkey
    LIMIT 1
)
WHERE (o.item_count IS NOT NULL OR r.s_suppkey IS NOT NULL)
ORDER BY o.item_count DESC NULLS LAST;
