WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
RegionalTotals AS (
    SELECT n.n_regionkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY n.n_regionkey
),
FinalResults AS (
    SELECT r.r_regionkey, 
           r.r_name,
           COALESCE(rt.total_sales, 0) AS total_sales,
           COUNT(DISTINCT ns.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN RegionalTotals rt ON r.r_regionkey = rt.n_regionkey
    LEFT JOIN nation ns ON ns.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT fr.r_regionkey, fr.r_name, fr.total_sales,
       (SELECT COUNT(*) FROM RankedSuppliers WHERE rnk = 1 AND rnk IS NOT NULL) AS top_supplier_count,
       (SELECT MAX(ps.ps_supplycost) FROM partsupp ps) - (SELECT MIN(ps.ps_supplycost) FROM partsupp ps) AS supply_cost_range
FROM FinalResults fr
WHERE (fr.total_sales > (SELECT AVG(total_sales) FROM FinalResults) OR fr.total_sales IS NULL)
  AND EXISTS (SELECT 1 FROM RankedSuppliers rs WHERE rs.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey) LIMIT 1)
ORDER BY fr.total_sales DESC NULLS LAST;
