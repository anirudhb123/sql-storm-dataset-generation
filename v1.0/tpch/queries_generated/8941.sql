WITH RegionSupplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region AS r
    JOIN nation AS n ON r.r_regionkey = n.n_regionkey
    JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer AS c
    LEFT JOIN orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, AVG(l.l_discount) AS avg_discount
    FROM lineitem AS l
    GROUP BY l.l_partkey
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, MIN(ps.ps_supplycost) AS min_supply_cost
    FROM partsupp AS ps
    GROUP BY ps.ps_partkey
)

SELECT 
    rs.r_name,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    li.total_quantity,
    li.avg_discount,
    ps.min_supply_cost
FROM RegionSupplier AS rs
JOIN CustomerOrders AS cs ON rs.supplier_count > 0
JOIN LineItemSummary AS li ON cs.order_count > 0
JOIN PartSupplierDetails AS ps ON li.l_partkey = ps.ps_partkey
WHERE rs.supplier_count > 5 AND cs.total_spent > 1000
ORDER BY rs.r_name, cs.total_spent DESC;
