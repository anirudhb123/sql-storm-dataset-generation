WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey
), TopSuppliers AS (
    SELECT 
        supplier.s_suppkey, 
        supplier.s_name 
    FROM 
        RankedSuppliers supplier 
    WHERE 
        supplier.rank <= 3
), OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_orderkey) AS item_count, 
        SUM(l.l_extendedprice) AS total_price,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, 
        c.c_mktsegment
), FinalReport AS (
    SELECT 
        od.o_orderkey,
        od.item_count,
        od.total_price,
        ts.s_name,
        od.c_mktsegment
    FROM 
        OrderDetails od
    JOIN 
        TopSuppliers ts ON od.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ts.s_suppkey)
)
SELECT 
    f.o_orderkey,
    f.item_count,
    f.total_price,
    f.s_name,
    f.c_mktsegment
FROM 
    FinalReport f
ORDER BY 
    f.total_price DESC;
