
WITH ranked_parts AS (
    SELECT p.*, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2))
),
filtered_customers AS (
    SELECT c.*, 
           COALESCE(SUM(o.o_totalprice) FILTER (WHERE o.o_orderstatus = 'O'), 0) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
),
distinct_nations AS (
    SELECT DISTINCT n.n_nationkey, n.n_name
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
)
SELECT 
    d.n_name AS nation_name,
    COUNT(DISTINCT CASE WHEN rp.rn < 4 THEN rp.p_partkey END) AS top_parts_count,
    AVG(fc.total_spent) AS avg_customer_spent,
    SUM(CASE WHEN fc.order_count = 0 THEN 1 ELSE 0 END) AS non_ordering_customers,
    STRING_AGG(DISTINCT rp.p_name, ', ') AS top_part_names,
    (SELECT COUNT(*) FROM filtered_customers) AS total_customers
FROM distinct_nations d 
LEFT JOIN ranked_parts rp ON d.n_nationkey = rp.p_partkey
LEFT JOIN filtered_customers fc ON d.n_nationkey = fc.c_nationkey
GROUP BY d.n_nationkey, d.n_name
HAVING COUNT(DISTINCT rp.p_partkey) > 0
ORDER BY nation_name DESC;
