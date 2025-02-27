WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), TopSuppliers AS (
    SELECT 
        nation_name,
        s_suppkey,
        s_name,
        total_supply_cost 
    FROM 
        RankedSuppliers 
    WHERE 
        supplier_rank <= 3
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
    ts.s_name AS top_supplier_name,
    COUNT(DISTINCT l.l_linenumber) AS total_lineitems
FROM 
    customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice, l.l_orderkey, ts.s_name
ORDER BY 
    c.c_custkey, total_lineitem_value DESC;
