WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_in_nation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT rc.c_custkey, rc.c_name, rc.total_spent
    FROM RankedCustomers rc
    WHERE rc.rank_in_nation <= 5
),
SupplierStats AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
PopularParts AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity_sold
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY l.l_partkey
    ORDER BY total_quantity_sold DESC
    LIMIT 10
)
SELECT tc.c_name, tc.total_spent, sp.total_supply_value, pp.total_quantity_sold
FROM TopCustomers tc
JOIN SupplierStats sp ON sp.ps_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN PopularParts pp ON ps.ps_partkey = pp.l_partkey)
JOIN PopularParts pp ON pp.l_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = tc.c_custkey)
ORDER BY tc.total_spent DESC, sp.total_supply_value DESC;
