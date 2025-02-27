WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighValueSuppliers AS (
    SELECT 
        s.s_name,
        ss.total_parts,
        ss.total_supply_cost,
        ss.avg_avail_qty,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supply_rank
    FROM SupplierStats ss
    WHERE ss.total_parts > 0 AND ss.total_supply_cost > (
        SELECT AVG(total_supply_cost)
        FROM SupplierStats
    )
)
SELECT 
    od.o_orderkey,
    od.total_sales,
    od.o_orderdate,
    COALESCE(hv.s_name, 'Unknown Supplier') AS supplier_name,
    hv.total_parts,
    hv.total_supply_cost,
    hv.avg_avail_qty
FROM OrderDetails od
LEFT JOIN HighValueSuppliers hv ON hv.supply_rank = (SELECT MIN(supply_rank) FROM HighValueSuppliers) 
WHERE od.order_rank <= 10
ORDER BY od.total_sales DESC, od.o_orderdate DESC;
