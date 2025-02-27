WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_mktsegment,
           CASE WHEN o.o_orderstatus = 'F' THEN 'Finalized' ELSE 'Pending' END AS order_status_description
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    )
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, p.p_retailprice,
           LEAD(p.p_name) OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS next_part_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT COALESCE(n.n_name, 'Unknown') AS nation_name,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns,
       STRING_AGG(CONCAT(s.s_name, ': ', s.s_acctbal) ORDER BY s.s_acctbal DESC) AS supplier_info
FROM lineitem l
JOIN HighValueOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN RankedSuppliers s ON l.l_suppkey = s.s_suppkey AND s.rank <= 3
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierParts ps ON l.l_partkey = ps.ps_partkey
WHERE l.l_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderdate > CURRENT_DATE - INTERVAL '90 days'
)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY total_revenue DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM lineitem) %% 10;
