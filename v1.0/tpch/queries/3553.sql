
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighSpenders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS spender_rank
    FROM CustomerOrders co
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    hs.c_name,
    hs.total_orders,
    hs.total_spent,
    CASE 
        WHEN sp.parts_supplied IS NULL THEN 'No Parts Provided'
        ELSE sp.parts_supplied::text
    END AS parts_supplied,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost
FROM HighSpenders hs
LEFT JOIN SupplierParts sp ON hs.total_orders = sp.parts_supplied
ORDER BY hs.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
