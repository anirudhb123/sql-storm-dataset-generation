WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
top_orders AS (
    SELECT o.order_rank, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.c_name
    FROM order_hierarchy o
    WHERE o.order_rank <= 5
),
part_supplier_info AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_brand, p.p_name, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_brand, p.p_name
),
aggregate_supplier AS (
    SELECT s.s_nationkey, SUM(ps.total_cost) AS supplier_cost
    FROM part_supplier_info ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_nationkey
),
total_spent AS (
    SELECT o.c_name, SUM(o.o_totalprice) AS total_spent
    FROM top_orders o
    GROUP BY o.c_name
)
SELECT n.n_name, COALESCE(ts.total_spent, 0) AS total_spent, 
       COALESCE(asupp.supplier_cost, 0) AS supplier_cost,
       (COALESCE(ts.total_spent, 0) - COALESCE(asupp.supplier_cost, 0)) AS net_spending
FROM nation n
LEFT JOIN total_spent ts ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ts.c_name)
LEFT JOIN aggregate_supplier asupp ON n.n_nationkey = asupp.s_nationkey
WHERE n.r_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'N%')
ORDER BY net_spending DESC;
