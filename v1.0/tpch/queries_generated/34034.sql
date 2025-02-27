WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey AND sh.level < 5
),
TotalCosts AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationSales AS (
    SELECT n.n_nationkey, 
           SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey
),
RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as rank
    FROM part p
)
SELECT n.r_name,
       ns.total_sales,
       COALESCE(sh.level, 0) AS supplier_level,
       rp.p_name,
       rp.rank
FROM nation n
JOIN NationSales ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
JOIN RankedParts rp ON rp.rank <= 10
WHERE ns.total_sales > (SELECT AVG(total_sales) FROM NationSales)
ORDER BY n.r_name, ns.total_sales DESC, supplier_level DESC;
