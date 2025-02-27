WITH RECURSIVE ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS rank_level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rs.rank_level + 1
    FROM supplier s
    JOIN ranked_suppliers rs ON s.s_suppkey = rs.s_suppkey
    WHERE s.s_acctbal > (rs.s_acctbal / 2)
),
top_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size > 10
),
customer_totals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
supplier_part_counts AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supply_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    tp.p_name AS part_name,
    tp.p_retailprice,
    COALESCE(ss.s_name, 'No Supplier') AS supplier_name,
    ct.total_spent,
    CASE 
        WHEN ct.total_spent > 100000 THEN 'High Value'
        WHEN ct.total_spent BETWEEN 50000 AND 100000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM customer_totals ct
LEFT JOIN customer c ON ct.c_custkey = c.c_custkey
JOIN top_parts tp ON ct.total_spent > tp.p_retailprice
LEFT JOIN (
    SELECT ps.ps_partkey, s.s_name
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
) ss ON tp.p_partkey = ss.ps_partkey
WHERE c.c_acctbal IS NOT NULL
AND c.c_name NOT LIKE '%test%'
ORDER BY ct.total_spent DESC, tp.p_retailprice DESC;
