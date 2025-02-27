WITH RECURSIVE category_hierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, p_type, 0 AS level
    FROM part
    WHERE p_size < 20
    UNION ALL
    SELECT p.partkey, p.p_name, p.p_size, p.p_retailprice * 1.1, p.p_type, ch.level + 1
    FROM part p
    JOIN category_hierarchy ch ON p.p_partkey = ch.p_partkey
    WHERE ch.level < 5
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
ranked_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_quantity DESC) AS rank_quantity
    FROM lineitem l
)
SELECT 
    r.r_name,
    COALESCE(ss.total_parts, 0) AS supplier_parts,
    COALESCE(os.total_sales, 0) AS customer_sales,
    AVG(ch.p_retailprice) AS avg_retail_price,
    MAX(l.rank_quantity) AS max_rank_quantity
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_summary ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN order_summary os ON n.n_nationkey = os.c_custkey
JOIN category_hierarchy ch ON TRUE
LEFT JOIN ranked_lineitems l ON ch.p_partkey = l.l_partkey
GROUP BY r.r_name
HAVING SUM(CASE WHEN l.l_quantity IS NULL THEN 1 ELSE 0 END) < 10
ORDER BY r.r_name DESC;
