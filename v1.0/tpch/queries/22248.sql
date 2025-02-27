WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
high_value_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
customer_order_counts AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(rs.rank, 0) AS supplier_rank,
    hvp.p_name AS high_value_part
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer_order_counts cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN ranked_suppliers rs ON n.n_nationkey = rs.s_suppkey
LEFT JOIN high_value_parts hvp ON hvp.p_partkey = (SELECT p.p_partkey
                                                    FROM part p 
                                                    WHERE p.p_name LIKE 'P%'
                                                    ORDER BY p.p_retailprice DESC
                                                    LIMIT 1 OFFSET (SELECT COUNT(*) FROM part) / 2)
WHERE r.r_name NOT LIKE '%land%'
   OR (rs.s_name IS NULL AND hvp.total_value IS NOT NULL)
ORDER BY n.n_name, r.r_name;
