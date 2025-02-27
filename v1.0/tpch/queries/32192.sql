WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = (SELECT MIN(r_regionkey) FROM region)
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region_hierarchy rh
    JOIN nation n ON rh.r_regionkey = n.n_regionkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rh.level < 5
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000 OR c.c_name LIKE 'A%'
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(cs.total_spent, 0) AS total_spent,
    ps.total_avail_qty,
    ps.total_cost,
    (CASE 
        WHEN ps.total_avail_qty IS NULL THEN 'No Supply'
        WHEN ps.total_avail_qty < 50 THEN 'Low Stock'
        ELSE 'In Stock'
    END) AS supply_status,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice) AS global_rank
FROM part p
LEFT JOIN customer_summary cs ON cs.c_custkey = (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_name IN (SELECT DISTINCT c_name FROM customer WHERE c_nationkey IS NOT NULL)
    LIMIT 1
)
JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN region_hierarchy rh ON rh.r_regionkey = (
    SELECT MAX(r_regionkey) FROM region
)
WHERE p.p_size BETWEEN 10 AND 20
ORDER BY p.p_retailprice, supply_status DESC;
