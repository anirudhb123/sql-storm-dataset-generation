WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey 
    WHERE nh.level < 3
),
part_supplier AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_order AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey
),
part_details AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
           COALESCE(ps.supplier_count, 0) AS supplier_count,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
)
SELECT nh.n_name AS nation_name,
       pd.p_name AS part_name,
       cd.total_orders,
       cd.total_spent,
       pd.total_supply_cost,
       pd.supplier_count,
       (pd.total_supply_cost / NULLIF(pd.supplier_count, 0)) AS avg_supply_cost_per_supplier
FROM nation_hierarchy nh
JOIN customer_order cd ON cd.c_custkey IN (
    SELECT DISTINCT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = nh.n_nationkey
)
JOIN lineitem li ON li.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey = cd.c_custkey
)
JOIN part_details pd ON pd.p_partkey = li.l_partkey
WHERE pd.price_rank = 1
ORDER BY nh.n_name, pd.total_supply_cost DESC
LIMIT 100;
