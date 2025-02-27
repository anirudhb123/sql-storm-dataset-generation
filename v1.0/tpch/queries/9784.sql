WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    pp.p_name AS part_name, 
    sc.s_name AS supplier_name, 
    sc.total_supply_cost,
    pp.total_quantity_sold
FROM 
    PopularParts pp
JOIN 
    SupplierCost sc ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sc.s_suppkey)
ORDER BY 
    sc.total_supply_cost DESC, 
    pp.total_quantity_sold DESC;