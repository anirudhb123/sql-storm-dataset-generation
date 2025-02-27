WITH RECURSIVE OrderCTE AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= DATE '2022-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, level + 1
    FROM orders o
    JOIN OrderCTE oc ON o.o_orderkey = oc.o_orderkey
    WHERE o.o_orderstatus = 'P' AND oc.level < 10
),
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionNations AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region, 
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS adjusted_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    ss.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN RegionNations r ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN SupplierSummary ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = l.l_partkey)
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY r.r_name, ss.total_supply_cost
HAVING SUM(CASE WHEN l.l_returnflag = 'Y' THEN 1 ELSE 0 END) < 10
ORDER BY adjusted_revenue DESC;
