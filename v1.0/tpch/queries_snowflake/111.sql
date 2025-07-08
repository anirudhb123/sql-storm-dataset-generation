WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 1000
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    p.p_name,
    r.r_name AS region,
    COALESCE(rs.s_name, 'Unknown') AS best_supplier,
    ch.total_spent,
    hp.avg_supplycost
FROM 
    part p
JOIN 
    HighValueParts hp ON p.p_partkey = hp.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey LIMIT 1)
LEFT JOIN 
    customer c ON p.p_partkey = c.c_custkey
LEFT JOIN 
    CustomerOrders ch ON c.c_custkey = ch.c_custkey
JOIN 
    nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
ORDER BY 
    region, total_spent DESC;
