
WITH SupplierSummary AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS number_of_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        supplier_name,
        nation_name,
        number_of_parts,
        total_available_quantity,
        total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rn
    FROM 
        SupplierSummary
)
SELECT 
    nation_name,
    SUM(number_of_parts) AS total_parts,
    SUM(total_available_quantity) AS total_quantity,
    AVG(total_supply_cost) AS avg_supply_cost,
    LISTAGG(supplier_name, ', ') WITHIN GROUP (ORDER BY total_supply_cost DESC) AS suppliers
FROM 
    HighValueSuppliers
WHERE 
    rn <= 3
GROUP BY 
    nation_name
ORDER BY 
    nation_name;
