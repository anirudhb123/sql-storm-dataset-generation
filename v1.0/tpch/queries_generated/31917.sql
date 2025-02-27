WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
), RankedOrders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate,
           DENSE_RANK() OVER (PARTITION BY o_orderdate ORDER BY o_totalprice DESC) as price_rank
    FROM orders
), FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY l.l_orderkey
), SupplierStats AS (
    SELECT sh.suppkey, sh.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.suppkey = ps.ps_suppkey
    GROUP BY sh.suppkey, sh.s_name
)
SELECT n.n_name, r.r_name, ss.s_name, 
       COALESCE(fs.revenue, 0) AS total_revenue, 
       s.part_count, s.total_avail_qty,
       p.p_name
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierStats s ON n.n_nationkey = s.suppkey
LEFT JOIN FilteredLineItems fs ON fs.l_orderkey IN (
    SELECT l_orderkey FROM lineitem l 
    WHERE l.l_suppkey = s.suppkey
)
LEFT JOIN part p ON p.p_partkey = (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey = s.suppkey
    ORDER BY ps.ps_availqty DESC
    LIMIT 1
)
WHERE n.n_nationkey IN (SELECT DISTINCT c_nationkey FROM customer WHERE c_acctbal > 2000)
  AND r.r_name NOT LIKE '%east%'
ORDER BY total_revenue DESC, s.part_count ASC;
