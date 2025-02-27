
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, h.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy h ON s.s_suppkey = h.s_suppkey
    WHERE h.level < 5
),
ordered_lines AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
high_value_orders AS (
    SELECT 
        ol.o_orderkey,
        ol.total_price,
        ROW_NUMBER() OVER (ORDER BY ol.total_price DESC) AS price_rank
    FROM ordered_lines ol
    WHERE ol.line_count > 2
)
SELECT 
    p.p_name,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_lineitem_value,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal IS NOT NULL) AS active_customers,
    MAX(h.s_acctbal) AS highest_supplier_acctbal
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN (
    SELECT s_h.s_name AS supplier_name, 
           s_h.level, 
           s_h.s_acctbal
    FROM supplier_hierarchy s_h
) h ON h.supplier_name = r.r_comment
WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
        WHERE p2.p_size IS NOT NULL
    )
GROUP BY p.p_name, r.r_name
HAVING COALESCE(SUM(ps.ps_availqty), 0) > 50
ORDER BY total_lineitem_value DESC
LIMIT 10;
