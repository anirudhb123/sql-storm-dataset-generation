WITH supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
part_info AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    p.p_name,
    p.total_availqty,
    p.avg_supplycost,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    si.nation_name
FROM 
    part_info p
LEFT JOIN 
    supplier_info si ON si.rank = 1
LEFT JOIN 
    supplier s ON si.s_suppkey = s.s_suppkey
WHERE 
    p.avg_supplycost < (SELECT AVG(ps_avg.avg_supplycost) FROM (SELECT AVG(ps.ps_supplycost) AS avg_supplycost FROM partsupp ps GROUP BY ps.ps_partkey) ps_avg) 
    AND p.total_availqty IS NOT NULL
ORDER BY 
    p.total_availqty DESC
LIMIT 10
UNION ALL
SELECT 
    'Not Available' as p_name,
    0 as total_availqty,
    0 as avg_supplycost,
    s.s_name,
    si.nation_name
FROM 
    supplier_info si
LEFT JOIN 
    supplier s ON si.s_suppkey = s.s_suppkey
WHERE 
    si.rank > 1
ORDER BY 
    supplier_name;
