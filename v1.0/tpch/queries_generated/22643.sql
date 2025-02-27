WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey,
           volatile_calculation(o.o_totalprice) AS adjusted_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 
                             WHERE o2.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE))
),
MaxShipdate AS (
    SELECT o.o_orderkey, MAX(l.l_shipdate) AS max_shipdate
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)

SELECT ns.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
       AVG(COALESCE(ps.ps_supplycost, 0)) AS avg_supply_cost,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_acctbal), '; ') AS supplier_info
FROM nation ns
LEFT JOIN customer c ON ns.n_nationkey = c.c_nationkey
JOIN HighValueOrders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND ps.ps_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rnk <= 3)
JOIN MaxShipdate ms ON o.o_orderkey = ms.o_orderkey AND l.l_shipdate = ms.max_shipdate
WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
GROUP BY ns.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 
       (SELECT AVG(COALESCE(o2.o_totalprice, 0)) FROM HighValueOrders o2 WHERE o2.o_orderdate < DATEADD(MONTH, -3, CURRENT_DATE))
ORDER BY total_revenue DESC NULLS LAST;
