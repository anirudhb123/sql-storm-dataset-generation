WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregateData AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= DATE '2022-01-01'
    GROUP BY p.p_partkey, p.p_name
),
RankedData AS (
    SELECT *, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM AggregateData
)
SELECT r.r_name AS region, n.n_name AS nation, sh.s_name AS supplier_name, rd.p_name AS part_name, rd.total_sales
FROM RankedData rd
JOIN partsupp ps ON rd.p_partkey = ps.ps_partkey
JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rd.sales_rank <= 10
  AND (sh.s_acctbal IS NOT NULL AND sh.s_acctbal > 5000)
ORDER BY region, nation, supplier_name;
