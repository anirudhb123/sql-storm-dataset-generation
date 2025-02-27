WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
avg_part_price AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
total_order_value AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    CASE 
        WHEN s_h.level IS NULL THEN 'No Supplier' 
        ELSE s_h.s_name 
    END AS supplier_name,
    COALESCE(avg.avg_supplycost, 0) AS average_supplycost,
    tv.total_value,
    CASE 
        WHEN tv.total_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders' 
    END AS order_status
FROM part p
LEFT JOIN avg_part_price avg ON p.p_partkey = avg.ps_partkey
LEFT JOIN total_order_value tv ON p.p_partkey = tv.o_orderkey
LEFT JOIN supplier_hierarchy s_h ON s_h.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey 
    ORDER BY ps.ps_supplycost DESC 
    LIMIT 1
)
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_size BETWEEN 5 AND 10
)
ORDER BY p.p_partkey, average_supplycost DESC;
