WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 500
    UNION ALL
    SELECT s.n_nationkey, p.ps_suppkey, p.s_name, p.s_acctbal, p.s_comment, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier p ON p.s_nationkey = sh.s_nationkey
    WHERE p.s_acctbal > sh.s_acctbal
),
AggregatedSales AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    AND o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_nationkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice < 100
    GROUP BY ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(s.s_name, 'Not Applicable') AS supplier_name,
    p.p_name AS part_name,
    p.avg_supply_cost,
    p.total_available,
    s.total_sales,
    RANK() OVER (PARTITION BY n.n_name ORDER BY s.total_sales DESC) AS sales_rank
FROM nation n
LEFT JOIN SupplierHierarchy s ON n.n_nationkey = s.s_nationkey
JOIN PartSupplierStats p ON p.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey ORDER BY ps.ps_availqty DESC LIMIT 1)
LEFT JOIN AggregatedSales AS a ON a.c_nationkey = n.n_nationkey
WHERE 
    a.total_sales IS NOT NULL
    AND (s.level <= 3 OR s.level IS NULL)
ORDER BY n.n_name, sales_rank;
