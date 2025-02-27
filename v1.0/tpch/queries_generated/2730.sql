WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
SupplierPartDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           p.p_partkey,
           p.p_name,
           ps.ps_availqty,
           ps.ps_supplycost,
           (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10 AND s.s_acctbal IS NOT NULL
),
CustomerOrderStats AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_orders_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 1
)
SELECT n.n_name,
       COALESCE(SUM(spd.total_supply_value), 0) AS total_supply_cost,
       MAX(cos.total_orders_value) AS max_customer_order_value,
       AVG(ro.o_totalprice) AS average_order_value
FROM nation n
LEFT JOIN SupplierPartDetails spd ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = spd.s_suppkey)
LEFT JOIN CustomerOrderStats cos ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cos.c_custkey)
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey)
WHERE n.n_regionkey IS NOT NULL
GROUP BY n.n_name
ORDER BY total_supply_cost DESC, max_customer_order_value DESC;
