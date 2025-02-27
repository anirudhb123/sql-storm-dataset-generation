WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopNations AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS sup_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    tn.n_name,
    rs.s_name,
    rs.total_cost
FROM 
    TopNations tn
JOIN 
    RankedSuppliers rs ON tn.n_name = rs.n_name
WHERE 
    rs.rank <= 3
ORDER BY 
    tn.n_name, rs.total_cost DESC;
