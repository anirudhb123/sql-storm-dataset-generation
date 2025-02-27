WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS bal_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.total_sales
    FROM 
        part p
    JOIN 
        PartSales ps ON p.p_partkey = ps.p_partkey
    WHERE 
        ps.total_sales > 100000
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    h.p_name AS part_name,
    s.s_name AS supplier_name,
    h.total_sales,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'No Account Balance'
        ELSE FORMAT(s.s_acctbal, 'C')
    END AS formatted_balance
FROM 
    HighValueParts h
LEFT JOIN 
    RankedSuppliers s ON h.p_partkey = s.ps_partkey AND s.bal_rank = 1
JOIN 
    supplier s2 ON s2.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s2.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL
    AND h.p_retailprice BETWEEN 50 AND 500
ORDER BY 
    total_sales DESC, nation, part_name;
