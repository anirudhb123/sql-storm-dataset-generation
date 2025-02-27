WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate AND o.o_orderstatus = 'O'
),
CategoryRevenue AS (
    SELECT p.p_type, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_type
),
RankedRegion AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT n.n_nationkey) DESC) AS region_rank
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    oh.o_orderkey,
    c.c_name,
    c.c_acctbal,
    crp.p_type,
    COALESCE(crp.total_revenue, 0) AS total_revenue,
    CASE WHEN crp.total_revenue IS NULL THEN 'No Revenue' ELSE 'Has Revenue' END AS revenue_status,
    r.r_name,
    r.nation_count
FROM OrderHierarchy oh
JOIN customer c ON oh.o_custkey = c.c_custkey
LEFT JOIN CategoryRevenue crp ON oh.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
)
JOIN RankedRegion r ON r.region_rank = (
    SELECT MIN(region_rank)
    FROM RankedRegion r2
    WHERE r2.nation_count >= r.nation_count
)
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
ORDER BY crp.total_revenue DESC, oh.o_orderkey;
