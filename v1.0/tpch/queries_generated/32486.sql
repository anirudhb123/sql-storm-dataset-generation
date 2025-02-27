WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE s.s_acctbal > sh.level * 500
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(li.l_discount) AS max_discount,
    COALESCE(SUM(ro.total_revenue), 0) AS total_revenue_last_6_months,
    nr.region_name,
    ROW_NUMBER() OVER (PARTITION BY nr.region_name ORDER BY SUM(ps.ps_availqty) DESC) AS part_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    recent_orders ro ON li.l_orderkey = ro.o_orderkey
LEFT JOIN 
    supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN 
    nation_region nr ON sh.s_nationkey = nr.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND (p.p_comment LIKE '%High Quality%' OR p.p_comment IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, nr.region_name
HAVING 
    SUM(ps.ps_availqty) > 50
ORDER BY 
    nr.region_name, total_available DESC;
