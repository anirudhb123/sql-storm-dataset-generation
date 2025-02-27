WITH RECURSIVE TotalSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) + ts.total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TotalSales ts ON c.c_custkey = ts.c_custkey
    WHERE 
        o.o_orderdate < '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, ts.total_spent
),
MaxSales AS (
    SELECT 
        c_nationkey,
        MAX(total_spent) AS max_spent
    FROM 
        TotalSales
    GROUP BY 
        c_nationkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ms.max_spent, 0) AS max_spent
    FROM 
        nation n
    LEFT JOIN 
        MaxSales ms ON n.n_nationkey = ms.c_nationkey
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
)
SELECT 
    ps.s_suppkey,
    s.s_name,
    ps.part_revenue,
    ns.n_name AS nation,
    ns.max_spent
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    PartSales psum ON ps.ps_partkey = psum.p_partkey
JOIN 
    NationSales ns ON s.s_nationkey = ns.n_nationkey
WHERE 
    psum.part_revenue > (SELECT AVG(part_revenue) FROM PartSales) 
    AND ns.max_spent IS NOT NULL
ORDER BY 
    psum.part_revenue DESC
LIMIT 10;
