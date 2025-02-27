WITH RECURSIVE DistinctNations AS (
    SELECT n_nationkey, n_name, n_regionkey 
    FROM nation 
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%East%')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey 
    FROM nation n
    INNER JOIN DistinctNations d ON n.n_regionkey = d.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_orders, 
           COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_orderdate) AS last_order_date 
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ps.p_partkey, 
       p.p_name, 
       COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
       COALESCE(cs.total_orders, 0) AS total_orders,
       ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN SupplierStats ss ON p.p_partkey = ss.s_suppkey
LEFT JOIN CustomerOrders cs ON cs.c_custkey = (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey IN (SELECT n_nationkey FROM DistinctNations)
    ORDER BY c.c_acctbal DESC 
    LIMIT 1
)
WHERE p.p_size IS NOT NULL AND p.p_size BETWEEN 10 AND 50
ORDER BY total_orders DESC, total_supply_cost ASC;

