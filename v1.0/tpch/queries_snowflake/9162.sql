WITH TotalSupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),

MaxSupplierCost AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        r.r_name AS region_name,
        MAX(t.total_cost) AS max_cost
    FROM 
        part p
    JOIN 
        TotalSupplierCost t ON p.p_partkey = t.ps_partkey
    JOIN 
        supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        p.p_partkey, p.p_name, r.r_name
),

QualifiedSuppliers AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        l.l_linenumber, 
        l.l_quantity, 
        l.l_extendedprice, 
        MAX(m.max_cost) AS max_part_cost
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        MaxSupplierCost m ON l.l_partkey = m.p_partkey
    WHERE 
        l.l_quantity > 50 AND 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, c.c_name, l.l_linenumber, l.l_quantity, l.l_extendedprice
)

SELECT 
    qs.o_orderkey,
    qs.c_name,
    SUM(qs.l_extendedprice) AS total_extended_price,
    COUNT(DISTINCT qs.l_linenumber) AS unique_line_items,
    AVG(qs.max_part_cost) AS average_max_part_cost
FROM 
    QualifiedSuppliers qs
GROUP BY 
    qs.o_orderkey, qs.c_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
