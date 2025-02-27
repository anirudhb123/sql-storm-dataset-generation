WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, 
           CAST(0 AS INTEGER) AS level
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.ps_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, 
           p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ph.level < 3
),
region_info AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rh.p_name, rh.p_brand, rh.p_type, rh.p_retailprice, ri.r_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count
FROM part_hierarchy rh
JOIN lineitem l ON rh.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN region_info ri ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = ri.r_regionkey))
WHERE l.l_returnflag = 'N'
GROUP BY rh.p_name, rh.p_brand, rh.p_type, rh.p_retailprice, ri.r_name
ORDER BY total_revenue DESC
LIMIT 10;
