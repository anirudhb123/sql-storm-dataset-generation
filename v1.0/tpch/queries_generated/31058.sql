WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate > '2022-01-01'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_partkey, 
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty, 
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT 
        co.c_custkey,
        SUM(co.o_totalprice) AS total_spent
    FROM CustomerOrders co
    GROUP BY co.c_custkey
    HAVING SUM(co.o_totalprice) > 10000
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        SUM(sp.ps_supplycost * sp.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(sp.ps_supplycost * sp.ps_availqty) DESC) AS rn
    FROM SupplierParts sp
    GROUP BY sp.s_suppkey, sp.s_name
),
FinalReport AS (
    SELECT 
        cu.c_name, 
        co.o_orderkey, 
        co.o_orderstatus,
        COALESCE(sp.p_name, 'No parts supplied') AS part_name,
        COALESCE(sp.ps_supplycost, 0) AS supply_cost,
        COALESCE(sp.ps_availqty, 0) AS avail_qty,
        hc.total_spent
    FROM CustomerOrders co
    LEFT JOIN SupplierParts sp ON co.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (
            SELECT ps.ps_partkey 
            FROM partsupp ps
            WHERE ps.ps_suppkey = sp.s_suppkey
        )
    )
    JOIN HighValueOrders hc ON co.c_custkey = hc.c_custkey
    ORDER BY co.o_orderdate DESC, hc.total_spent DESC
)
SELECT * 
FROM FinalReport 
WHERE total_spent IS NOT NULL AND total_spent > 10000 AND part_name IS NOT NULL 
ORDER BY total_spent DESC, o_orderdate DESC
LIMIT 10;
