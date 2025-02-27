WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, CAST(NULL AS VARCHAR(55)) AS parent_name
    FROM part
    WHERE p_name LIKE '%plastic%'
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, ph.p_name AS parent_name
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_retailprice < 100 AND p.p_size > 10
),
customer_satisfaction AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(CASE 
            WHEN o.o_orderstatus = 'F' THEN 1 
            WHEN o.o_orderstatus = 'P' AND l.l_discount > 0.2 THEN 0.5
            ELSE 0 
        END) AS satisfaction_score
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
discounted_parts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        STRING_AGG(p.p_name, ', ') AS part_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 10
    GROUP BY p.p_partkey
    HAVING COUNT(*) FILTER (WHERE ps.ps_supplycost < 50) > 0
)
SELECT 
    nh.n_name AS nation_name,
    COALESCE(SUM(ps.total_cost), 0) AS total_discounted_cost,
    COUNT(DISTINCT cs.c_custkey) AS satisfied_customers,
    ROW_NUMBER() OVER (PARTITION BY nh.n_nationkey ORDER BY SUM(ps.total_cost) DESC) AS part_rank,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cs.satisfaction_score) OVER() AS median_satisfaction
FROM nation nh
LEFT JOIN discounted_parts ps ON nh.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = ps.p_partkey LIMIT 1)
LEFT JOIN customer_satisfaction cs ON cs.c_custkey IN (SELECT c.c_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = ps.p_partkey))
GROUP BY nh.n_name, nh.n_nationkey
HAVING COUNT(ps.p_partkey) > 0 AND COUNT(cs.c_custkey) > 10
ORDER BY 2 DESC, 3 ASC;
