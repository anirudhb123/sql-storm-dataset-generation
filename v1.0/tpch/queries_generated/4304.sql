WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        hs.o_orderkey,
        hs.total_order_value,
        CASE 
            WHEN hs.total_order_value IS NULL THEN 'No Orders'
            WHEN rs.total_supply_cost IS NULL THEN 'No Supply Cost'
            ELSE 'Has Orders and Supply Cost'
        END AS status
    FROM RankedSuppliers rs
    LEFT JOIN HighValueOrders hs ON rs.s_suppkey = hs.o_orderkey
),
FinalResults AS (
    SELECT 
        s.s_name,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(o.total_order_value, 0) AS total_order_value,
        s.status
    FROM SupplierDetails s
    FULL OUTER JOIN HighValueOrders o ON s.o_orderkey = o.o_orderkey
)
SELECT 
    f.s_name,
    f.total_supply_cost,
    f.total_order_value,
    f.status
FROM FinalResults f
WHERE f.total_supply_cost > 5000 AND f.total_order_value > 5000
ORDER BY f.total_supply_cost DESC, f.total_order_value DESC;
