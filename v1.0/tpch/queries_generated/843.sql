WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn 
    FROM supplier s
),
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighVolumeCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent 
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierPartData AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_ordered
    FROM partsupp ps
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
)
SELECT 
    n.n_name, 
    SUM(spd.ps_availqty) AS total_available_qty,
    COUNT(DISTINCT hvc.c_custkey) AS number_of_high_volume_customers,
    AVG(r.s_acctbal) AS avg_supplier_balance
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers r ON s.s_suppkey = r.s_suppkey 
LEFT JOIN SupplierPartData spd ON s.s_suppkey = spd.ps_suppkey 
LEFT JOIN HighVolumeCustomers hvc ON hvc.total_spent > 5000
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(r.s_suppkey) > 0
ORDER BY total_available_qty DESC, avg_supplier_balance DESC;
