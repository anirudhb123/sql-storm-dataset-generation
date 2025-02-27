WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = 0  -- Example root level criteria
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
filtered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_size,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 5
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    sp.s_name AS supplier_name,
    sp.total_supply_value,
    fp.p_name AS part_name,
    fp.p_retailprice
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer_orders co ON n.n_nationkey = co.c_custkey
LEFT JOIN supplier_parts sp ON n.n_nationkey = sp.s_suppkey
JOIN filtered_parts fp ON sp.s_suppkey = fp.p_partkey
WHERE r.r_name LIKE 'A%' 
  AND co.order_count > 0 
  AND fp.price_rank <= 10
ORDER BY total_spent DESC, supplier_name ASC;
