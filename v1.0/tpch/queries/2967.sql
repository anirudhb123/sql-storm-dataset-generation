
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        ss.total_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_cost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_cost > 10000
)
SELECT 
    ts.s_name,
    ts.total_cost,
    ts.part_count,
    os.revenue,
    os.item_count
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderStats os ON ts.rank = (SELECT COUNT(*) FROM TopSuppliers ts2 WHERE ts2.total_cost > ts.total_cost) + 1
WHERE 
    ts.part_count > 5
ORDER BY 
    ts.rank
LIMIT 10;
