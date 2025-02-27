
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
PartDetail AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        CONCAT(p.p_name, ' (', p.p_brand, ')') AS part_description 
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 20.00 AND 500.00
),
LineItemAggregation AS (
    SELECT 
        l.l_partkey, 
        COUNT(*) AS total_lines, 
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    s.s_name, 
    p.part_description, 
    l.total_lines, 
    l.total_revenue, 
    r.r_name AS region_name
FROM 
    SupplierInfo s
JOIN 
    PartDetail p ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = s.s_nationkey)
JOIN 
    LineItemAggregation l ON p.p_partkey = l.l_partkey
JOIN 
    region r ON r.r_regionkey = s.s_nationkey
WHERE 
    l.total_revenue > 10000
ORDER BY 
    s.s_name, l.total_revenue DESC;
