WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_supply_value,
        sp.unique_parts,
        sp.order_count,
        RANK() OVER (ORDER BY sp.total_supply_value DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ts.s_name AS top_supplier,
    ts.total_supply_value,
    ts.unique_parts,
    ts.order_count
FROM 
    RankedOrders ro
LEFT JOIN 
    TopSuppliers ts ON ro.o_orderkey = (SELECT MIN(l.l_orderkey) 
                                         FROM lineitem l 
                                         WHERE l.l_orderkey = ro.o_orderkey 
                                         AND l.l_returnflag = 'N')
WHERE 
    ts.supplier_rank <= 5 
    OR ts.supplier_rank IS NULL
ORDER BY 
    ro.o_orderdate, ro.o_totalprice DESC;
