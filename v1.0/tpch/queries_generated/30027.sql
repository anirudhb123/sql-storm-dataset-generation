WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS VARCHAR(255)) AS hierarchy
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(CONCAT(sh.hierarchy, ' -> ', s.s_name) AS VARCHAR(255))
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
region_supplier AS (
    SELECT r.r_name, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name, s.s_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    MAX(l.l_tax) AS max_tax,
    COALESCE(rs.total_supply_cost, 0) AS total_supply_cost,
    sh.hierarchy
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN ranked_orders o ON l.l_orderkey = o.o_orderkey AND o.order_rank <= 10
LEFT JOIN region_supplier rs ON p.p_container = rs.r_name
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE p.p_size > 20 AND l.l_shipdate <= CURRENT_DATE
GROUP BY p.p_name, rs.total_supply_cost, sh.hierarchy
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY avg_price DESC, total_supply_cost DESC;
