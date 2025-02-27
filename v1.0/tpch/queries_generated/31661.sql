WITH RECURSIVE price_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS totalRevenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS totalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.part_count,
        ss.totalSupplyCost,
        ROW_NUMBER() OVER (ORDER BY ss.totalSupplyCost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        supplier_summary ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.totalSupplyCost > 10000
)
SELECT 
    ps.p_name,
    ps.totalRevenue,
    ts.s_name AS supplier_name,
    ts.part_count,
    ts.totalSupplyCost
FROM 
    price_summary ps
LEFT JOIN 
    top_suppliers ts ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = ts.s_suppkey)
WHERE 
    ps.totalRevenue > (SELECT AVG(totalRevenue) FROM price_summary)
ORDER BY 
    ps.totalRevenue DESC, ts.totalSupplyCost DESC
LIMIT 100;
