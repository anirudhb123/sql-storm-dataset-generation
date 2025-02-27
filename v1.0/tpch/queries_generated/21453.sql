WITH RecursivePart AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_brand, 
        p_size, 
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) as rn
    FROM 
        part
    WHERE 
        p_size IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        total_revenue > 10000
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand
    FROM 
        RecursivePart rp
    WHERE 
        rp.rn <= 5
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    CASE 
        WHEN si.s_acctbal IS NULL THEN 'Unknown Supplier' 
        ELSE si.s_name 
    END AS supplier_name, 
    os.total_revenue, 
    os.part_count,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue' 
        ELSE CAST(os.total_revenue AS varchar) 
    END AS revenue_status
FROM 
    FilteredParts fp
LEFT JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
FULL OUTER JOIN 
    OrderStats os ON os.o_orderkey = (SELECT MAX(o_orderkey) FROM orders)
WHERE 
    (fp.p_brand LIKE '%A%' OR fp.p_brand IS NULL)
ORDER BY 
    COALESCE(os.total_revenue, 0) DESC, 
    fp.p_name ASC;
