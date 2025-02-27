WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_name, s.s_nationkey, n.n_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierDetails
)
SELECT 
    supplier_name,
    nation_name,
    part_names,
    total_available_quantity,
    total_supply_cost,
    total_orders
FROM 
    RankedSuppliers
WHERE 
    cost_rank <= 5
ORDER BY 
    nation_name, total_supply_cost DESC;
