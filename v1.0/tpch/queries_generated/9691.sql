WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
    UNION ALL
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON ps.ps_partkey = sc.p_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    n.n_name AS supplier_nation,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    MAX(l.l_extendedprice) AS max_extended_price
FROM 
    SupplyChain sc
JOIN 
    supplier s ON sc.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON sc.p_partkey = l.l_partkey
GROUP BY 
    n.n_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
