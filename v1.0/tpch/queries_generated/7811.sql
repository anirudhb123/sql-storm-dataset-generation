WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) + sc.total_cost AS total_cost
    FROM 
        SupplyChain sc
    JOIN 
        supplier s ON s.s_suppkey = sc.s_suppkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        sc.total_cost < 100000
),
TotalCosts AS (
    SELECT 
        n.n_name,
        SUM(sc.total_cost) AS nation_total_cost
    FROM 
        SupplyChain sc
    JOIN 
        nation n ON sc.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    tc.nation_total_cost
FROM 
    TotalCosts tc
JOIN 
    nation n ON n.n_nationkey = tc.s_nationkey
WHERE 
    tc.nation_total_cost > (SELECT AVG(nation_total_cost) FROM TotalCosts)
ORDER BY 
    tc.nation_total_cost DESC;
