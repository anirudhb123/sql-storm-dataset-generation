
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        AVG(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    rv.nation,
    COUNT(DISTINCT hp.p_partkey) AS high_value_part_count,
    SUM(rv.total_supply_cost) AS total_supplier_cost
FROM 
    RankedSuppliers rv
JOIN 
    HighValueParts hp ON rv.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey)
WHERE 
    rv.rnk <= 5
GROUP BY 
    rv.nation
ORDER BY 
    total_supplier_cost DESC;
