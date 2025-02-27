WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2021-12-31'
),
TopOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_name,
           n.n_name AS nation_name
    FROM RankedOrders o
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.order_rank <= 5
),
SupplierCosts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost) > 1000
)
SELECT t.o_orderkey,
       t.o_orderdate,
       t.o_totalprice,
       t.c_name,
       t.nation_name,
       SUM(s.total_supply_cost) AS total_supplier_cost
FROM TopOrders t
LEFT JOIN SupplierCosts s ON t.o_orderkey = s.ps_partkey
GROUP BY t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name, t.nation_name
ORDER BY t.o_totalprice DESC
LIMIT 50;
