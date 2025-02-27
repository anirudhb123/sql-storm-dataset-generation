WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        AVG(l.l_quantity) AS avg_quantity_per_item
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.unique_parts,
    os.avg_quantity_per_item,
    ps.p_name,
    ps.total_available_quantity,
    ps.avg_supply_cost,
    ts.s_name,
    ts.total_supply_cost
FROM 
    OrderSummary os
JOIN 
    PartSupplierSummary ps ON os.unique_parts > ps.total_available_quantity
JOIN 
    TopSuppliers ts ON os.total_revenue > ts.total_supply_cost
ORDER BY 
    os.total_revenue DESC, os.o_orderdate;
