WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    JOIN 
        region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = s.nation_name)
    WHERE 
        s.rank <= 3
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.r_name AS supplier_region,
    ts.s_address,
    ts.s_phone,
    ts.s_acctbal,
    (SELECT COUNT(DISTINCT p.p_partkey) 
     FROM part p 
     JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
     WHERE ps.ps_suppkey = ts.s_suppkey) AS part_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts
FROM 
    TopSuppliers ts
LEFT JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    ts.s_suppkey, ts.s_name, ts.r_name, ts.s_address, ts.s_phone, ts.s_acctbal
ORDER BY 
    ts.s_acctbal DESC;
