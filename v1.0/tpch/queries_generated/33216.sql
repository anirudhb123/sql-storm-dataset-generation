WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.level < 5
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
      AND o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
),
PartSupplied AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS available_quantity,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.available_quantity,
        ps.supplier_count,
        RANK() OVER (PARTITION BY ps.supplier_count ORDER BY ps.available_quantity DESC) AS part_rank
    FROM part p
    JOIN PartSupplied ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(ts.total_revenue) AS total_sales,
    AVG(RP.available_quantity) AS avg_available_quantity,
    MAX(RP.part_rank) AS max_part_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN TotalSales ts ON c.c_custkey = ts.o_orderkey
LEFT JOIN RankedParts RP ON RP.p_partkey = ANY (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 50
)
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_sales DESC
LIMIT 10;
