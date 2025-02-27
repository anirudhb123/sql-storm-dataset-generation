WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_rank
    FROM orders
    WHERE o_orderstatus = 'O'
), SupplierParts AS (
    SELECT ps_partkey, ps_suppkey, SUM(ps_availqty) AS total_avail_qty,
           AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey, ps_suppkey
), RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM supplier s
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS orders_count,
           CASE WHEN AVG(o.o_totalprice) > 500 THEN 'High' ELSE 'Low' END AS spending_category
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT rh.order_rank, co.c_name, co.total_spent, co.spending_category,
       sp.avg_supply_cost, sp.total_avail_qty, ns.n_name
FROM OrderHierarchy rh
JOIN CustomerOrders co ON rh.o_custkey = co.c_custkey
LEFT JOIN (SELECT ps_partkey, SUM(ps_availqty) AS total_avail_qty, 
                  AVG(ps_supplycost) AS avg_supply_cost 
           FROM partsupp 
           GROUP BY ps_partkey) sp ON sp.ps_partkey IN (SELECT l.l_partkey 
                                                         FROM lineitem l 
                                                         WHERE l.l_orderkey = rh.o_orderkey)
LEFT JOIN nation ns ON ns.n_nationkey = (SELECT c.c_nationkey 
                                          FROM customer c 
                                          WHERE c.c_custkey = rh.o_custkey)
WHERE co.total_spent IS NOT NULL
ORDER BY rh.order_rank, co.total_spent DESC
LIMIT 50;
