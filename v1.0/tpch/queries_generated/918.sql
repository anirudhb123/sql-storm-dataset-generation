WITH SupplyStats AS (
    SELECT 
        ps.partkey,
        COUNT(DISTINCT ps.suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ss.supplier_count,
    ss.total_avail_qty,
    hvc.c_name AS high_value_customer,
    hvc.total_spent AS customer_total_spent
FROM part p
LEFT JOIN SupplyStats ss ON p.p_partkey = ss.partkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey IN (
    SELECT l.l_suppkey 
    FROM lineitem l 
    WHERE l.l_partkey = p.p_partkey
)
WHERE p.p_retailprice > (
    SELECT AVG(p1.p_retailprice) FROM part p1
)
ORDER BY p.p_partkey
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
