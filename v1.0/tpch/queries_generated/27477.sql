WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        COUNT(ps.ps_partkey) AS supply_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY COUNT(ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    rs.nation_name,
    rs.s_name,
    pp.p_name,
    pp.total_quantity_sold,
    CONCAT('Supplier "', rs.s_name, '" from ', rs.s_address, ' has supplied the popular part "', pp.p_name, '" with a total quantity of ', pp.total_quantity_sold) AS message
FROM 
    RankedSuppliers rs
JOIN 
    PopularParts pp ON rs.supply_count > 5 
ORDER BY 
    rs.nation_name, pp.total_quantity_sold DESC;
