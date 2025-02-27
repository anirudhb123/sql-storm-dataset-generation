WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_addr,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation,
        STRING_AGG(s_name || ' (Total Cost: ' || total_supply_cost || ')', ', ') AS suppliers_list
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
    GROUP BY 
        nation
)
SELECT 
    r.r_name AS region,
    ts.suppliers_list
FROM 
    region r
LEFT JOIN 
    (
        SELECT 
            nation,
            STRING_AGG(suppliers_list, '; ') AS suppliers_list
        FROM 
            TopSuppliers
        GROUP BY 
            nation
    ) ts ON ts.nation = r.r_name
ORDER BY 
    region;
