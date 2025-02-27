WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        t.s_name,
        t.total_supply_value
    FROM 
        RankedSuppliers t
    JOIN 
        nation n ON n.n_name = t.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.supplier_rank <= 3
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    os.o_orderkey,
    os.o_orderstatus,
    os.total_line_item_value,
    ts.r_name,
    ts.s_name AS top_supplier
FROM 
    OrdersSummary os
LEFT OUTER JOIN 
    TopSuppliers ts ON os.total_line_item_value > 10000  -- Only consider orders above a threshold
WHERE 
    EXISTS (
        SELECT 1 
        FROM lineitem l
        WHERE l.l_orderkey = os.o_orderkey
          AND l.l_returnflag = 'R'
    )
ORDER BY 
    os.total_line_item_value DESC, ts.r_name, ts.top_supplier;
