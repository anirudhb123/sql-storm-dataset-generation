WITH supplier_part AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier 
            WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = 1)
        )
), 
nation_supplier AS (
    SELECT 
        n.n_name,
        SUM(sp.ps_supplycost * sp.ps_availqty) AS total_cost
    FROM 
        nation n
    JOIN 
        supplier_part sp ON n.n_nationkey = sp.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.total_cost,
    COUNT(DISTINCT sp.p_partkey) AS unique_parts,
    AVG(sp.ps_supplycost) AS avg_supply_cost
FROM 
    nation_supplier ns
JOIN 
    supplier_part sp ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = sp.s_suppkey)
GROUP BY 
    ns.n_name, ns.total_cost
ORDER BY 
    total_cost DESC
LIMIT 10;
