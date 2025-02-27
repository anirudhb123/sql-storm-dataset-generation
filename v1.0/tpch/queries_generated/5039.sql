WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.region_name
    FROM 
        RankedSuppliers s
    WHERE 
        s.rn <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        c.c_name, 
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 1000
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
)
SELECT 
    t.s_suppkey, 
    t.s_name, 
    t.s_acctbal, 
    o.o_orderkey, 
    o.o_totalprice, 
    o.o_orderdate, 
    o.c_name, 
    o.item_count
FROM 
    TopSuppliers t
JOIN 
    HighValueOrders o ON t.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE 
            l.l_orderkey IN (SELECT o.o_orderkey FROM orders o)
        GROUP BY 
            ps.ps_suppkey
    )
ORDER BY 
    t.s_acctbal DESC, o.o_totalprice DESC;
