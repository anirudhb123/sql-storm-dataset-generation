WITH RECURSIVE tiered_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS tier
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, t.tier + 1
    FROM orders o
    JOIN tiered_orders t ON o.o_orderkey = t.o_orderkey
    WHERE o.o_orderstatus = 'F' AND t.tier < 5
),
filtered_part AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           CASE 
               WHEN p.p_size IS NULL THEN 'UNKNOWN'
               ELSE CAST(p.p_size AS VARCHAR)
           END AS size_label
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
order_summary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS failed_orders,
    AVG(s.total_supply_cost) AS avg_supplier_cost,
    MAX(t.o_totalprice) AS max_tiered_total_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, '(', filtered_part.size_label, ')'), '; ') AS part_details
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier_info s ON s.s_suppkey = (SELECT MAX(s2.s_suppkey) FROM supplier_info s2)
JOIN order_summary o ON o.o_orderkey = (SELECT o3.o_orderkey FROM orders o3 WHERE o3.o_orderstatus = 'O')
LEFT JOIN filtered_part p ON p.p_partkey = (SELECT MIN(p2.p_partkey) FROM part p2 WHERE p2.p_brand LIKE 'Brand%')
FULL OUTER JOIN tiered_orders t ON t.o_orderkey = o.o_orderkey
WHERE r.r_name IS NOT NULL AND n.n_name IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5 AND AVG(s.total_supply_cost) IS NOT NULL;
