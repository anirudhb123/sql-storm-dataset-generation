WITH RECURSIVE region_nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    UNION ALL
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, CONCAT(r.r_name, ' & ', n.n_name)
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_name NOT IN (SELECT n_name FROM nation WHERE n_regionkey = r.r_regionkey)
),
supplier_stats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
high_value_orders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS value_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    rn.n_name AS nation,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS average_revenue,
    MAX(ss.total_cost) AS max_supplier_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_suppkey, ')'), ', ') AS suppliers
FROM lineitem l
JOIN high_value_orders o ON l.l_orderkey = o.o_orderkey
JOIN region_nations rn ON rn.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rn.n_name)
LEFT JOIN supplier_stats ss ON ss.s_suppkey = l.l_suppkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY rn.n_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5 AND MAX(ss.rank) < 10
ORDER BY nation DESC
LIMIT 10 OFFSET 5;
