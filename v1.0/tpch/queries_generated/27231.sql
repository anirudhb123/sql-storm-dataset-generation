WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', p.p_name, ' with cost $', FORMAT(ps.ps_supplycost, 2)) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RankedSuppliers AS (
    SELECT 
        supplier_name,
        nation_name,
        part_name,
        available_quantity,
        supply_cost,
        supplier_info,
        DENSE_RANK() OVER (PARTITION BY nation_name ORDER BY available_quantity DESC) AS rank
    FROM 
        SupplierDetails
)
SELECT 
    supplier_name,
    nation_name,
    part_name,
    available_quantity,
    supply_cost,
    supplier_info
FROM 
    RankedSuppliers
WHERE 
    rank <= 5
ORDER BY 
    nation_name, available_quantity DESC;
