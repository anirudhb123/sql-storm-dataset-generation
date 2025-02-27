WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS VARCHAR(255)) AS full_name, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n.n_nationkey, CAST(CONCAT(sh.full_name, ' > ', s.s_name) AS VARCHAR(255)), sh.level + 1
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN supplier_hierarchy sh ON n.n_regionkey = sh.s_nationkey
)
, part_supply AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    p.p_name AS part_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    AVG(o.o_totalprice) FILTER (WHERE o.o_orderstatus = 'F') AS avg_fulfilled_order_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(COALESCE(sh.level, 0)) AS max_supplier_level,
    CASE 
        WHEN SUM(li.l_discount) > 0 THEN 'Discounted Orders Found'
        ELSE 'No Discounts Available'
    END AS discount_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
JOIN orders o ON o.o_custkey = c.c_custkey
JOIN lineitem li ON li.l_orderkey = o.o_orderkey
LEFT JOIN part_supply ps ON li.l_partkey = ps.p_partkey AND ps.rank = 1
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE li.l_shipdate >= '2022-01-01' AND li.l_shipdate < '2023-01-01'
GROUP BY r.r_name, n.n_name, c.c_name, p.p_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY revenue DESC;
