WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > ch.c_acctbal
), TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01'
    GROUP BY l.l_orderkey
), SupplierStats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS unique_parts, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 0
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn_order
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
    AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), RegionSupplier AS (
    SELECT r.r_regionkey, r.r_name, SUM(ss.unique_parts) AS total_parts
    FROM region r
    LEFT JOIN SupplierStats ss ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ss.s_suppkey))
    GROUP BY r.r_regionkey, r.r_name
)
SELECT ch.c_nationkey, ch.c_name, COALESCE(SUM(r.o_totalprice), 0) AS total_spent, 
       COALESCE(rs.total_parts, 0) AS parts_count,
       STRING_AGG(DISTINCT r.o_orderdate::varchar, ', ') AS order_dates
FROM CustomerHierarchy ch
LEFT JOIN RankedOrders r ON ch.c_custkey = r.o_orderkey
LEFT JOIN RegionSupplier rs ON rs.r_regionkey = ch.c_nationkey
WHERE ch.level < 4 
AND ch.c_name NOT LIKE 'Temp%'
GROUP BY ch.c_nationkey, ch.c_name
HAVING SUM(COALESCE(r.o_totalprice, 0)) > 1000
ORDER BY total_spent DESC, parts_count DESC
LIMIT 10;
