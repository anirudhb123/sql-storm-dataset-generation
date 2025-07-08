
WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LISTAGG(p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS parts_supplied,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        supplier_name,
        supplier_address,
        nation_name,
        region_name,
        total_available_quantity,
        total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM 
        SupplierDetails
)
SELECT 
    supplier_name,
    supplier_address,
    nation_name,
    region_name,
    total_available_quantity,
    total_supply_cost,
    CONCAT('Supplier: ', supplier_name, ' | Address: ', supplier_address, ' | Nation: ', nation_name, ' | Region: ', region_name) AS supplier_info
FROM 
    TopSuppliers
WHERE 
    rank <= 10
ORDER BY 
    total_supply_cost DESC;
