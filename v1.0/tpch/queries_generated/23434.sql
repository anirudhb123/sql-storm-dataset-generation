WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            ELSE CASE 
                WHEN s.s_acctbal < 1000 THEN 'Low' 
                WHEN s.s_acctbal BETWEEN 1000 AND 10000 THEN 'Medium' 
                ELSE 'High' 
            END 
        END AS acctbal_category
    FROM 
        supplier s
    WHERE 
        s.s_comment IS NOT NULL AND s.s_comment NOT LIKE '%deprecated%'
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    ns.r_name AS nation_region,
    fs.acctbal_category,
    os.total_revenue,
    COALESCE(NULLIF(NTH_VALUE(ns.n_name, 2) OVER (PARTITION BY ns.r_name ORDER BY ns.n_name), ''), 'No Nation') AS second_nation_name,
    COUNT(DISTINCT fs.s_suppkey) AS supplier_count
FROM 
    RankedParts p
LEFT JOIN 
    FilteredSuppliers fs ON p.p_partkey = ANY(SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey)
LEFT JOIN 
    OrderStats os ON fs.s_nationkey = os.o_custkey
LEFT JOIN 
    NationRegion ns ON fs.s_nationkey = ns.n_nationkey
WHERE 
    p.price_rank <= 5 
    AND os.total_revenue IS NOT NULL 
    AND (fs.acctbal_category = 'High' OR fs.acctbal_category IS NULL)
GROUP BY 
    p.p_name, ns.r_name, fs.acctbal_category, os.total_revenue
HAVING 
    COUNT(DISTINCT fs.s_suppkey) > 0
ORDER BY 
    p.p_retailprice DESC NULLS LAST;
