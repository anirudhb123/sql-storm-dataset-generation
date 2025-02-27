WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
TotalLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
SELECT n.n_name,
       r.r_name,
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
       SUM(COALESCE(t.total_revenue, 0)) AS total_revenue,
       AVG(s.s_acctbal) AS avg_acctbal,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.acct_rank <= 3
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN TotalLineItems t ON ps.ps_partkey = t.l_partkey
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM TopOrders WHERE order_rank <= 5)
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
WHERE r.r_name IS NOT NULL
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 0
   AND SUM(t.total_revenue) IS NOT NULL
ORDER BY total_revenue DESC, avg_acctbal DESC;
