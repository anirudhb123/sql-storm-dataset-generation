WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100.00)
),

SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),

RegionNations AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
    HAVING 
        COUNT(n.n_nationkey) >= 2
),

BestSuppliers AS (
    SELECT 
        st.s_suppkey,
        st.total_cost
    FROM 
        SupplierTotals st
    WHERE 
        st.total_cost > (
            SELECT 
                AVG(total_cost) FROM SupplierTotals
        )
)

SELECT 
    r.r_name,
    SUM(CASE 
        WHEN lp.l_discount IS NOT NULL THEN lp.l_extendedprice * (1 - lp.l_discount)
        ELSE lp.l_extendedprice 
    END) AS adjusted_revenue,
    COUNT(DISTINCT bp.p_partkey) AS available_parts,
    AVG(bp.p_retailprice) AS avg_price_by_brand
FROM 
    lineitem lp
LEFT JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    RankedParts bp ON lp.l_partkey = bp.p_partkey AND bp.rnk <= 10
JOIN 
    partsupp ps ON bp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    RegionNations rn ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rn.r_regionkey)
WHERE 
    o.o_orderdate = (SELECT MAX(o2.o_orderdate) FROM orders o2)
AND 
    s.s_suppkey IN (SELECT b.s_suppkey FROM BestSuppliers b)
GROUP BY 
    r.r_name
ORDER BY 
    adjusted_revenue DESC
LIMIT 10;
