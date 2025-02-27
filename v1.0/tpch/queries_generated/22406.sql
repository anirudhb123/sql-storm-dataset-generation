WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank_price
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal < 1000 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS acctbal_category
    FROM 
        supplier s
    WHERE 
        s.s_comment NOT LIKE '%defective%'
), 
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name AS nation,
    p.p_name AS part_name,
    e.total_lineitems,
    e.total_revenue,
    f.acctbal_category,
    COALESCE(NULLIF(AVG(r.rank_price), 0), 1) AS avg_rank_price
FROM 
    RankedParts r
INNER JOIN 
    partsupp ps ON r.p_partkey = ps.ps_partkey
RIGHT JOIN 
    FilteredSuppliers f ON ps.ps_suppkey = f.s_suppkey
JOIN 
    customer c ON f.s_nationkey = c.c_nationkey
LEFT JOIN 
    OrderStats e ON c.c_custkey = e.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    (f.acctbal_category = 'High' OR e.total_revenue > 10000)
    AND r.rank_price < 5
ORDER BY 
    avg_rank_price DESC,
    total_revenue DESC
LIMIT 100 OFFSET 10;
