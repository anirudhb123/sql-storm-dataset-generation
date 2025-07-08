WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    t.s_name,
    t.total_avail_qty,
    t.avg_supply_cost,
    od.total_value,
    od.line_count
FROM 
    SupplierStats t
LEFT JOIN 
    TopSuppliers ts ON t.s_suppkey = ts.s_suppkey AND ts.supplier_rank <= 10
JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT l.l_orderkey 
                                         FROM lineitem l 
                                         WHERE l.l_suppkey = t.s_suppkey 
                                         ORDER BY l.l_extendedprice DESC 
                                         LIMIT 1)
WHERE 
    t.total_avail_qty > (SELECT AVG(total_avail_qty) FROM SupplierStats)
ORDER BY 
    t.avg_supply_cost DESC, od.total_value DESC;