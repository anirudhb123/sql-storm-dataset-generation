WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ranked_supply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_quantity) OVER (PARTITION BY c.c_custkey) AS total_quantity
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
filtered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           (SELECT AVG(ps_supplycost) FROM ranked_supply rs WHERE rs.ps_partkey = p.p_partkey) AS avg_supplycost
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
        WHERE p2.p_container IS NOT NULL
    )
)
SELECT n.n_name AS nation_name, 
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(co.o_totalprice) AS total_revenue,
       COUNT(DISTINCT fp.p_partkey) AS num_filtered_parts,
       SUM(fp.p_retailprice) / NULLIF(COUNT(fp.p_partkey), 0) AS avg_retail_price,
       MIN(fp.avg_supplycost) AS min_avg_supply_cost
FROM nation_hierarchy n
JOIN customer_orders co ON n.n_nationkey = co.c_custkey
JOIN filtered_parts fp ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = co.c_custkey)
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT co.o_orderkey) > 5
ORDER BY total_revenue DESC;
