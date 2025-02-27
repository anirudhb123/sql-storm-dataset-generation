
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = 'GERMANY'
    )
    WHERE s.s_acctbal > sh.s_acctbal 
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
), SupplierPart AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_retailprice, ps.ps_availqty, 
           COALESCE(ps.ps_availqty, 0) AS adjusted_qty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice < 300
), HighVolumeLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    WHERE l.l_shipdate > DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, 
       COALESCE(j.total_value, 0) AS total_last_month,
       COALESCE(r.rn, 0) AS order_rank
FROM SupplierHierarchy sh
LEFT JOIN HighVolumeLineItems j ON sh.s_suppkey = (
    SELECT l.l_suppkey 
    FROM lineitem l 
    WHERE l.l_orderkey = j.l_orderkey 
    LIMIT 1
)
LEFT JOIN RankedOrders r ON r.o_orderkey = (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_suppkey = sh.s_suppkey 
    LIMIT 1
)
WHERE sh.level <= 5
ORDER BY sh.s_acctbal DESC, total_last_month DESC;
