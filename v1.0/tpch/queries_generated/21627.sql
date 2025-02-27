WITH RecursiveSupplier AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, rs.level + 1
    FROM supplier s
    JOIN RecursiveSupplier rs ON s.s_nationkey = rs.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > rs.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availability
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) >= (
        SELECT AVG(ps_availqty) 
        FROM partsupp 
        WHERE ps_supplycost < 100 
        GROUP BY ps_partkey
    )
),
NationJoin AS (
    SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
    HAVING COUNT(DISTINCT o.o_orderkey) > (SELECT AVG(order_count) FROM (SELECT COUNT(DISTINCT o_orderkey) AS order_count FROM orders GROUP BY o_custkey) AS ord)
)

SELECT r.r_name, ns.order_count, ps.p_name, ps.total_availability, 
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY ns.order_count DESC) AS rank,
       COALESCE(rs.s_acctbal, 0) AS supplier_balance,
       CASE 
           WHEN ns.order_count > 10 THEN 'High Demand'
           WHEN ns.order_count IS NULL THEN 'No Orders'
           ELSE 'Moderate Demand'
       END AS demand_level
FROM region r
JOIN NationJoin ns ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = r.r_name)
LEFT JOIN FilteredParts ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'O'))
LEFT JOIN RecursiveSupplier rs ON rs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.r_name)
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name, rank;
