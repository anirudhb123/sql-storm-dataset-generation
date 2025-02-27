WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cu.c_custkey,
        cu.c_name,
        cu.total_spent
    FROM CustomerOrders cu
    WHERE cu.total_spent > (
        SELECT AVG(total_spent)
        FROM CustomerOrders
    )
)
SELECT 
    ps.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(su.total_parts, 0) AS supplier_part_count,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 5000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierStats su ON ps.ps_suppkey = su.s_suppkey
LEFT JOIN CustomerOrders cs ON p.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey IN (SELECT h.c_custkey FROM HighValueCustomers h)
    )
)
ORDER BY p.p_partkey DESC, supplier_part_count DESC;
