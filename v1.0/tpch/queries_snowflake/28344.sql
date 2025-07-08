
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        COUNT(ps.ps_supplycost) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, p.p_name
),
QualifiedSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.nation_name,
        r.p_name,
        r.supply_count,
        r.total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY r.nation_name ORDER BY r.total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers r
)
SELECT 
    qs.nation_name,
    LISTAGG(qs.s_name, ', ') WITHIN GROUP (ORDER BY qs.s_name) AS supplier_names,
    LISTAGG(qs.p_name, '; ') WITHIN GROUP (ORDER BY qs.p_name) AS part_names,
    SUM(qs.total_supply_cost) AS aggregate_supply_cost
FROM 
    QualifiedSuppliers qs
WHERE 
    qs.rank <= 3
GROUP BY 
    qs.nation_name
ORDER BY 
    qs.nation_name;
