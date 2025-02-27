WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
    GROUP BY ps.ps_partkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
),
combined_results AS (
    SELECT nh.n_name AS nation_name,
           COUNT(DISTINCT ps.ps_partkey) AS distinct_parts,
           SUM(co.o_totalprice) AS total_order_value
    FROM nation_hierarchy nh
    LEFT JOIN part_supplier ps ON nh.n_nationkey = ps.ps_partkey
    LEFT JOIN customer_orders co ON co.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = nh.n_nationkey
    )
    GROUP BY nh.n_name
)
SELECT *,
       CASE 
           WHEN total_order_value IS NULL THEN 'No Orders'
           WHEN total_order_value > 10000 THEN 'High Value'
           ELSE 'Medium/Low Value'
       END AS order_value_category
FROM combined_results
WHERE EXISTS (
    SELECT 1
    FROM part p
    WHERE p.p_partkey IN (SELECT ps.ps_partkey FROM part_supplier ps)
    AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
        WHERE p2.p_mfgr = 'ManufacturerX'
    )
)
ORDER BY nation_name, distinct_parts DESC, total_order_value DESC;
