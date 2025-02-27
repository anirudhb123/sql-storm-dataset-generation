WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey 
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey 
    FROM nation n
    JOIN nation_hierarchy nh ON nh.n_regionkey = n.n_nationkey
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS sup_rank
    FROM supplier s 
    WHERE s.s_acctbal IS NOT NULL AND s.s_name IS NOT NULL
),
part_supplier_price AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           ps.ps_availqty * ps.ps_supplycost AS total_cost,
           CASE 
               WHEN ps.ps_supplycost IS NULL THEN 'No Cost'
               ELSE 'Cost Available'
           END AS cost_status
    FROM partsupp ps
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS adjusted_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY o.o_orderkey, o.o_totalprice
),
aggregated_data AS (
    SELECT p.p_partkey, p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           COALESCE(SUM(p.price * ps.ps_availqty), 0) AS total_supply_cost
    FROM part p
    LEFT JOIN part_supplier_price ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT n.n_name, a.p_partkey, a.p_name, 
       a.total_supply_cost, d.s_acctbal AS supplier_acctbal,
       CASE 
           WHEN a.supplier_count > 0 THEN 'Available'
           ELSE 'Not Available' 
       END AS supply_status,
       SUM(CASE 
           WHEN d.sup_rank = 1 THEN 1 ELSE 0 
       END) OVER (PARTITION BY n.n_name) AS top_supplier_count
FROM aggregated_data a
JOIN nation_hierarchy n ON a.supplier_count = n.n_nationkey
JOIN supplier_details d ON a.supplier_count = d.sup_rank
WHERE n.n_name IS NOT NULL 
AND d.s_acctbal > (SELECT AVG(s.s_acctbal) FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
ORDER BY n.n_name, total_supply_cost DESC;
