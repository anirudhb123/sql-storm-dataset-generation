WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT ro.o_orderkey,
           ro.o_totalprice,
           COUNT(li.l_orderkey) AS line_count,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM RankedOrders ro
    LEFT JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE ro.order_rank <= 10
    GROUP BY ro.o_orderkey, ro.o_totalprice
),
NationSummary AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_partkey,
       p.p_name,
       p.p_retailprice,
       COALESCE(s.total_parts, 0) AS total_parts,
       COALESCE(n.total_acctbal, 0) AS total_acctbal,
       CASE 
           WHEN H.revenue IS NULL THEN 'No Revenue' 
           ELSE 'Total Revenue: ' || CAST(H.revenue AS CHAR(20)) 
       END AS revenue_info
FROM part p
LEFT JOIN SupplierDetails s ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%Supplier%'))
LEFT JOIN NationSummary n ON p.p_mfgr IN (SELECT DISTINCT s.s_name FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_availqty > 0)
LEFT JOIN HighValueOrders H ON H.line_count > 5 AND H.o_totalprice > 1000
ORDER BY p.p_partkey
